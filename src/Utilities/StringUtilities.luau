--!optimize 2
--!strict

local StringUtilities = {}

function StringUtilities.GetNumberFromString(Value: number | string, Default: number)
	if Value == nil or type(Value) ~= "string" then
		return if Value and type(Value) == "number" then Value else Default or 0
	else
		local Number = tonumber(Value)
		if Number then
			return Number
		else
			local Match = string.match(Value, "%-?%d+%.?%d*")
			return if Match then tonumber(Match) or Default or 0 else Default or 0
		end
	end
end

return table.freeze(StringUtilities)
