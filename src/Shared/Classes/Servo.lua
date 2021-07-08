-- Servo class, meant to replace the Constraint version when we don't need replication
-- Dynamese (Enduo)
-- 07.08.2021


local Servo = {}
Servo.__index = Servo



local ABS = math.abs
local SIGN = math.sign
local RAD = math.rad


-- Creates an infinite torque servo motor
-- Actuates about the actuator's local Y axis
--  current relative orientation and positioning is maintained
-- !! NOTE: Does not replicate when used on client !!
-- @param actuator <BasePart> serves as the servo motor
-- @param actuated <BasePart> this is rotated by the motor
-- @param speed <float> [0, INF) in degrees
-- @returns <Servo>
function Servo.new(actuator, actuated, speed)
    local weld = Instance.new("WeldConstraint")
    local relative = actuator.CFrame:ToObjectSpace(actuated.CFrame)

    local self = setmetatable({
        _Relative = relative;
        _Weld = weld;

        Actuator = actuator;
        Actuated = actuated;
        Speed = RAD(speed); -- avoids excessive RAD calls in :Step()
        Angle = 0;
        Goal = 0;
        Delta = 0;
    }, Servo)

    weld.Part0 = actuator
    weld.Part1 = actuated
    weld.Parent = actuator

	return setmetatable(self, Servo)
end


-- @param angle <float> [0, 360)
function Servo:SetGoal(angle)
    self.Goal = RAD(angle % 360)
    self.Delta = self.Goal - self.Angle
end


-- @param dt <float>
function Servo:Step(dt)
    if (ABS(self.Delta) > 0) then
        -- Calculate what happened in the elapsed dt
        local dir = SIGN(self.Goal - self.Angle)
        local willRotate = dir * self.Speed * dt

        -- Prevent overshoot
        if (ABS(willRotate) > ABS(self.Delta)) then
            self.Angle = self.Goal
        else
            self.Angle += willRotate
        end

        self.Delta = self.Goal - self.Angle

        -- Apply
        self._Weld.Enabled = false
        self.Actuated.CFrame = self.Actuator.CFrame * self._Relative * CFrame.Angles(0, self.Angle, 0)
        self._Weld.Enabled = true
    end
end


return Servo
