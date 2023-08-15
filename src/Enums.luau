--!optimize 2
--!strict

local Enums = {}

Enums.SerializeAs = table.freeze(setmetatable({
	TOML = 1;
	JSON = 2;
	YAML = 3;
}, {__index = table.freeze({"TOML", "JSON", "YAML"})}))

Enums.Options = table.freeze(setmetatable({
	Validate = 1;
	Upload = 2;
	Grab = 3;
}, {__index = table.freeze({"Validate", "Upload", "Grab"})}))

return table.freeze(Enums)
