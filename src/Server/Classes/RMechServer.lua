-- RMech class for the server
-- Dynamese (Enduo)
-- 07.08.2021



local DeepObject = require(script.Parent.DeepObject)
local Servo = require(script.Parent.Servo)

local RMechServer = setmetatable({}, DeepObject)
RMechServer.__index = RMechServer


-- Makes a new RMech with methods for the server to manage
-- @param user <Player> to create a mech for
-- @param mechAsset <DeepAsset> of the mech
-- @param loadout <table> == nil, loadout configuration
-- @returns <RMechServer>
function RMechServer.new(user, mechAsset, loadout)
    local mechBase = mechAsset.Base:Clone()
    local lower = mechAsset.Lower:Clone()
    local upper = mechAsset.Upper:Clone()

    lower:SetPrimaryPartCFrame(mechBase.PrimaryPart.CFrame)
    upper:SetPrimaryPartCFrame(lower.UpperConnector.CFrame)

	local self = setmetatable(DeepObject.new({
        Base = mechBase;
        Servos = {};
        Lower = lower;
        Upper = upper;
    }), RMechServer)

    -- Actuators
    self:MakeActuator("Torso", lower.UpperConnector, upper.PrimaryPart)
    if (mechAsset.Configuration.HasLeftArmActuator) then
        self:MakeActuator("ArmLeft", upper.LeftArmActuator, upper.LeftArm.PrimaryPart)
    end
    if (mechAsset.Configuration.HasRightArmActuator) then
        self:MakeActuator("ArmRight", upper.RightArmActuator, upper.RightArm.PrimaryPart)
    end

    -- Stick our model to our capsule
    self.Modules.WeldUtil:WeldParts(mechBase.PrimaryPart, lower.PrimaryPart)

    -- Level & name
    mechBase.Capsule.COM.Level.Attachment1 = workspace.Ground.Ground
    mechBase.Name = "RMech" .. user.UserId

    -- Parenting
    lower.Parent = mechBase.Skeleton
    upper.Parent = mechBase.Skeleton
    mechBase.Parent = workspace.RMechs

    self.Modules.ThreadUtil.Spawn(function()
        while true do
            local dt = wait()

            self.Servos.Torso:SetGoal(math.random(0, 360))
            self.Servos.ArmRight:SetGoal(math.random(0, 360))

           -- self.Servos.Torso:Step(dt)
            self.Servos.ArmRight:Step(dt)
        end
    end)

	return self
end


-- Creates a joint actuator
-- @param name of the actuator
-- @param actuator <BasePart>
-- @param actuated <BasePart
function RMechServer:MakeActuator(name, actuator, actuated)
    local servo, servoModel = Servo.new2(actuator, actuated)

    self.Modules.WeldUtil:WeldParts(servo.Actuator, actuator)
    self.Modules.WeldUtil:WeldParts(servo.Actuated, actuated)

    self.Servos[name] = servo
    servoModel.Parent = self.Base.Actuators
end


return RMechServer
