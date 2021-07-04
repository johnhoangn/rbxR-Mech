local RMech = {}
RMech.__index = RMech


-- Creates a new RMech, a mech wrapper
-- @param realMech <model>
function RMech.new(realMech)
    local mass = 0

    for _, c in ipairs(realMech:GetDescendants()) do
        if (c:IsA("BasePart") and not c.Massless) then
            mass += c:GetMass()
        end
    end

	local self = setmetatable({
		Mech = realMech;
        Mass = mass;
        COM = realMech.Capsule.COM;
	}, RMech)

	return self
end


function RMech:GetAttribute(attr)
    return self.Mech:GetAttribute(attr)
end


return RMech
