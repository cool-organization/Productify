--!optimize 2
--!strict
local ProductifyUtility = require("./Utilities/ProductifyUtility")

local function Validate(ProductifyData: any)
	assert(ProductifyUtility.IsProductify(ProductifyData))
end

return Validate
