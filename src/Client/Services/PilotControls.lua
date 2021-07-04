local PilotControls = {}

local Network, MetronomeService, FakeCAS, RunService

local Camera
local MechFolder

local HUGE = math.huge
local CLAMP = math.clamp
local ABS = math.abs
local ZERO_VECTOR = Vector3.new()
local XZ_VECTOR = Vector3.new(1, 0, 1)

local Steer = 0

local InputStates = nil
local Controllers = nil
local CurrentMech = nil
local MetronomeJobID = nil


-- Enables keyboard control
function PilotControls:BindInputs()
    FakeCAS:BindAction("ThrottleMax", function(_, state, _, _)
        InputStates.W = state == Enum.UserInputState.Begin

        if (InputStates.W) then
            Controllers.Throttle:SetThrottle(1)
        else
            Controllers.Throttle:SetThrottle(InputStates.S and -1 or 0)
        end
    end, Enum.KeyCode.W)

    FakeCAS:BindAction("ThrottleMin", function(_, state, _, _)
        InputStates.S = state == Enum.UserInputState.Begin

        if (InputStates.S) then
            Controllers.Throttle:SetThrottle(-1)
        else
            Controllers.Throttle:SetThrottle(InputStates.W and 1 or 0)
        end
    end, Enum.KeyCode.S)

    FakeCAS:BindAction("SteerLeft", function(_, state, _, _)
        InputStates.A = state == Enum.UserInputState.Begin

        if (InputStates.A) then
            Steer = 1
        else
            Steer = InputStates.D and -1 or 0
        end
    end, Enum.KeyCode.A)

    FakeCAS:BindAction("SteerRight", function(_, state, _, _)
        InputStates.D = state == Enum.UserInputState.Begin

        if (InputStates.D) then
            Steer = -1
        else
            Steer = InputStates.A and 1 or 0
        end
    end, Enum.KeyCode.D)
end


-- Disables controls
function PilotControls:UnbindInputs()
    FakeCAS:UnbindAction("ThrottleMax")
    FakeCAS:UnbindAction("ThrottleMin")
    FakeCAS:UnbindAction("SteerLeft")
    FakeCAS:UnbindAction("SteerRight")
end


-- Updates RMech velocity
function PilotControls:Move(dt)
    local COM = CurrentMech.COM
    local currentSpeed = COM.AssemblyLinearVelocity.Magnitude
    local calculatedSpeed = Controllers.Throttle.Velocity
    local absoluteSpeed = ABS(calculatedSpeed)
    local moveVector = COM.CFrame.LookVector * calculatedSpeed

    if (ABS(currentSpeed) > 5 and ABS(currentSpeed - absoluteSpeed) / absoluteSpeed > 0.9) then
        Controllers.Throttle:SetVelocity(0)
    end

    COM.Velocity = Vector3.new(
        moveVector.X,
        COM.Velocity.Y,
        moveVector.Z
    )

    Controllers.Throttle:Step(dt)
end


-- Updates RMech turn
function PilotControls:Steer(dt)
    local turnRate = CurrentMech:GetAttribute("TurnRate") -- Degrees/s
    Controllers.Gyro.CFrame *= CFrame.Angles(0, dt * Steer * (turnRate * math.pi) / 180, 0)
end


-- Receive and link RMech to pilot controls
-- @param mechUID <string>
function PilotControls:SetMech(mechUID)
    local realMech = MechFolder:WaitForChild(mechUID)

    realMech:WaitForChild("Capsule")
    realMech.Capsule:WaitForChild("COM")

    --[[
    if (realMech == nil) then
        self.LocalPlayer:Kick("ERR: R-Mech never replicated")
    end
    ]]

    CurrentMech = self.Classes.RMech.new(realMech)

    InputStates = {
        W = false;
        A = false;
        S = false;
        D = false;
    }

    Controllers = {
        Throttle = self.Classes.ThrottleController.new(
            CurrentMech:GetAttribute("Acceleration"),
            CurrentMech:GetAttribute("Deceleration"),
            -CurrentMech:GetAttribute("RevSpeed"),
            CurrentMech:GetAttribute("FwdSpeed")
        );
        Move = realMech.Capsule.COM.Mover;
        Gyro = realMech.Capsule.COM.Gyro;
    }

    MetronomeJobID = MetronomeService:BindToFrequency(60, function(dt)
        self:Move(dt)
        self:Steer(dt)
    end)

    --Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CameraSubject = realMech

    self:BindInputs()
    self.MechChanged:Fire(realMech)
end


-- Unlinks an RMech from the pilot controls
function PilotControls:RemoveMech()
    self:UnbindInputs()

    if (CurrentMech ~= nil) then
        CurrentMech = nil
        InputStates = nil
        Controllers = nil
        MetronomeService:Unbind(MetronomeJobID)
    end

    --Camera.CameraType = Enum.CameraType.Custom

    self.MechChanged:Fire(nil)
end


function PilotControls:EngineInit()
    Network = self.Services.Network
    MetronomeService = self.Services.MetronomeService
    RunService = self.RBXServices.RunService

    FakeCAS = self.Modules.FakeCAS

    Camera = workspace.CurrentCamera
    MechFolder = workspace.RMechs

	self.MechChanged = self.Classes.Signal.new()
end


function PilotControls:EngineStart()
	Network:HandleRequestType(Network.NetRequestType.MechAssigned, function(dt, mechUID)
        self:SetMech(mechUID)
    end)
end


return PilotControls