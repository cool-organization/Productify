--!optimize 2
--!strict
local ProductifyUtilities = require("./Utilities/ProductifyUtilities")

local function Validate(ProductifyData: any)
	assert(ProductifyUtilities.IsProductify(ProductifyData))
end

return Validate
