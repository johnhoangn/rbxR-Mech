local Template = {}
Template.__index = Template


function Template.new(...)
	local self = setmetatable({
		
	}, Template)
	
	return self
end


return Template
