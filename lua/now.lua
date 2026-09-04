local smartload = require("smartload")
---@param module string
return function (module)
	if smartload.off[module] then
		return
	end

	require(module)
end
