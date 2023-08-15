-- t: a runtime typechecker for Roblox

local t = {}

function t.type(typeName)
	return function(value)
		local valueType = type(value)
		if valueType == typeName then
			return true
		else
			return false, string.format("%* expected, got %*", typeName, valueType)
		end
	end
end

function t.typeof(typeName)
	return function(value)
		local valueType = typeof(value)
		if valueType == typeName then
			return true
		else
			return false, string.format("%* expected, got %*", typeName, valueType)
		end
	end
end

--[[**
	matches any type except nil

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
function t.any(value)
	if value ~= nil then
		return true
	else
		return false, "any expected, got nil"
	end
end

--Lua primitives

--[[**
	ensures Lua primitive boolean type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
t.boolean = t.typeof("boolean")

--[[**
	ensures Lua primitive thread type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
t.thread = t.typeof("thread")

--[[**
	ensures Lua primitive callback type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
t.callback = t.typeof("function")

--[[**
	ensures Lua primitive none type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
t.none = t.typeof("nil")

--[[**
	ensures Lua primitive string type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
t.string = t.typeof("string")

--[[**
	ensures Lua primitive table type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
t.table = t.typeof("table")

--[[**
	ensures Lua primitive userdata type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
t.userdata = t.type("userdata")

function t.Enum(value)
	local typeSuccess, typeError = t.userdata(value)
	if not typeSuccess then
		return false, typeError or "?"
	end

	local Enums = require("../Enums")
	for _, enum in Enums do
		if enum == value then
			return true
		end
	end

	return false, string.format("Enum expected, got %*", tostring(value))
end

--[[**
	ensures value is a number and non-NaN

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
function t.number(value)
	local valueType = typeof(value)
	if valueType == "number" then
		if value == value then
			return true
		else
			return false, "unexpected NaN value"
		end
	else
		return false, string.format("number expected, got %*", valueType)
	end
end

--[[**
	ensures value is NaN

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
function t.nan(value)
	local valueType = typeof(value)
	if valueType == "number" then
		if value ~= value then
			return true
		else
			return false, "unexpected non-NaN value"
		end
	else
		return false, string.format("number expected, got %*", valueType)
	end
end

local t_union

--[[**
	ensures value is a given literal value

	@param literal The literal to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.literal(...)
	local size = select("#", ...)
	if size == 1 then
		local literal = ...
		return function(value)
			if value ~= literal then
				return false, string.format("expected %*, got %*", tostring(literal), tostring(value))
			end

			return true
		end
	else
		local literals = table.create(size)
		for index = 1, size do
			local value = select(index, ...)
			literals[index] = t.literal(value)
		end

		return t_union(table.unpack(literals, 1, size))
	end
end

--[[**
	DEPRECATED
	Please use t.literal
**--]]
t.exactly = t.literal

--[[**
	Returns a t.union of each key in the table as a t.literal

	@param keyTable The table to get keys from

	@returns True iff the condition is satisfied, false otherwise
**--]]
function t.keyOf(keyTable)
	local keys = {}
	local length = 0
	for key in keyTable do
		length += 1
		keys[length] = key
	end

	return t.literal(table.unpack(keys, 1, length))
end

--[[**
	Returns a t.union of each value in the table as a t.literal

	@param valueTable The table to get values from

	@returns True iff the condition is satisfied, false otherwise
**--]]
function t.valueOf(valueTable)
	local values = {}
	local length = 0
	for _, value in valueTable do
		length += 1
		values[length] = value
	end

	return t.literal(table.unpack(values, 1, length))
end

--[[**
	ensures value is an integer

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
function t.integer(value)
	local success, errMsg = t.number(value)
	if not success then
		return false, errMsg or ""
	end

	if value % 1 == 0 then
		return true
	else
		return false, string.format("integer expected, got %*", value)
	end
end

--[[**
	ensures value is a number where min <= value

	@param min The minimum to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.numberMin(min)
	return function(value)
		local success, errMsg = t.number(value)
		if not success then
			return false, errMsg or ""
		end

		if value >= min then
			return true
		else
			return false, string.format("number >= %* expected, got %*", min, value)
		end
	end
end

--[[**
	ensures value is a number where value <= max

	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.numberMax(max)
	return function(value)
		local success, errMsg = t.number(value)
		if not success then
			return false, errMsg
		end

		if value <= max then
			return true
		else
			return false, string.format("number <= %* expected, got %*", max, value)
		end
	end
end

--[[**
	ensures value is a number where min < value

	@param min The minimum to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.numberMinExclusive(min)
	return function(value)
		local success, errMsg = t.number(value)
		if not success then
			return false, errMsg or ""
		end

		if min < value then
			return true
		else
			return false, string.format("number > %* expected, got %*", min, value)
		end
	end
end

--[[**
	ensures value is a number where value < max

	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.numberMaxExclusive(max)
	return function(value)
		local success, errMsg = t.number(value)
		if not success then
			return false, errMsg or ""
		end

		if value < max then
			return true
		else
			return false, string.format("number < %* expected, got %*", max, value)
		end
	end
end

--[[**
	ensures value is a number where value > 0

	@returns A function that will return true iff the condition is passed
**--]]
t.numberPositive = t.numberMinExclusive(0)

--[[**
	ensures value is a number where value < 0

	@returns A function that will return true iff the condition is passed
**--]]
t.numberNegative = t.numberMaxExclusive(0)

--[[**
	ensures value is a number where min <= value <= max

	@param min The minimum to use
	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.numberConstrained(min, max)
	assert(t.number(min))
	assert(t.number(max))
	local minCheck = t.numberMin(min)
	local maxCheck = t.numberMax(max)

	return function(value)
		local minSuccess, minErrMsg = minCheck(value)
		if not minSuccess then
			return false, minErrMsg or ""
		end

		local maxSuccess, maxErrMsg = maxCheck(value)
		if not maxSuccess then
			return false, maxErrMsg or ""
		end

		return true
	end
end

--[[**
	ensures value is a number where min < value < max

	@param min The minimum to use
	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.numberConstrainedExclusive(min, max)
	assert(t.number(min))
	assert(t.number(max))
	local minCheck = t.numberMinExclusive(min)
	local maxCheck = t.numberMaxExclusive(max)

	return function(value)
		local minSuccess, minErrMsg = minCheck(value)
		if not minSuccess then
			return false, minErrMsg or ""
		end

		local maxSuccess, maxErrMsg = maxCheck(value)
		if not maxSuccess then
			return false, maxErrMsg or ""
		end

		return true
	end
end

--[[**
	ensures value matches string pattern

	@param string pattern to check against

	@returns A function that will return true iff the condition is passed
**--]]
function t.match(pattern)
	assert(t.string(pattern))
	return function(value)
		local stringSuccess, stringErrMsg = t.string(value)
		if not stringSuccess then
			return false, stringErrMsg
		end

		if string.match(value, pattern) == nil then
			return false, string.format("%q failed to match pattern %q", value, pattern)
		end

		return true
	end
end

--[[**
	ensures value is either nil or passes check

	@param check The check to use

	@returns A function that will return true iff the condition is passed
**--]]
function t.optional(check)
	assert(t.callback(check))
	return function(value)
		if value == nil then
			return true
		end

		local success, errMsg = check(value)
		if success then
			return true
		else
			return false, string.format("(optional) %*", errMsg or "")
		end
	end
end

--[[**
	matches given tuple against tuple type definition

	@param ... The type definition for the tuples

	@returns A function that will return true iff the condition is passed
**--]]
function t.tuple(...)
	local checks = {...}
	return function(...)
		local args = {...}
		for index, check in checks do
			local success, errMsg = check(args[index])
			if success == false then
				return false, string.format("Bad tuple index #%*:\n\t%*", index, errMsg or "")
			end
		end

		return true
	end
end

--[[**
	ensures all keys in given table pass check

	@param check The function to use to check the keys

	@returns A function that will return true iff the condition is passed
**--]]
function t.keys(check)
	assert(t.callback(check))
	return function(value)
		local tableSuccess, tableErrMsg = t.table(value)
		if tableSuccess == false then
			return false, tableErrMsg or ""
		end

		for key in value do
			local success, errMsg = check(key)
			if success == false then
				return false, string.format("bad key %*:\n\t%*", tostring(key), errMsg or "")
			end
		end

		return true
	end
end

--[[**
	ensures all values in given table pass check

	@param check The function to use to check the values

	@returns A function that will return true iff the condition is passed
**--]]
function t.values(check)
	assert(t.callback(check))
	return function(value)
		local tableSuccess, tableErrMsg = t.table(value)
		if tableSuccess == false then
			return false, tableErrMsg or ""
		end

		for key, val in value do
			local success, errMsg = check(val)
			if success == false then
				return false, string.format("bad value for key %*:\n\t%*", tostring(key), errMsg or "")
			end
		end

		return true
	end
end

--[[**
	ensures value is a table and all keys pass keyCheck and all values pass valueCheck

	@param keyCheck The function to use to check the keys
	@param valueCheck The function to use to check the values

	@returns A function that will return true iff the condition is passed
**--]]
function t.map(keyCheck, valueCheck)
	assert(t.callback(keyCheck))
	assert(t.callback(valueCheck))
	local keyChecker = t.keys(keyCheck)
	local valueChecker = t.values(valueCheck)

	return function(value)
		local keySuccess, keyErr = keyChecker(value)
		if not keySuccess then
			return false, keyErr or ""
		end

		local valueSuccess, valueErr = valueChecker(value)
		if not valueSuccess then
			return false, valueErr or ""
		end

		return true
	end
end

--[[**
	ensures value is a table and all keys pass valueCheck and all values are true

	@param valueCheck The function to use to check the values

	@returns A function that will return true iff the condition is passed
**--]]
function t.set(valueCheck)
	return t.map(valueCheck, t.literal(true))
end

do
	local arrayKeysCheck = t.keys(t.integer)
	--[[**
		ensures value is an array and all values of the array match check

		@param check The check to compare all values with

		@returns A function that will return true iff the condition is passed
	**--]]
	function t.array(check)
		assert(t.callback(check))
		local valuesCheck = t.values(check)

		return function(value)
			local keySuccess, keyErrMsg = arrayKeysCheck(value)
			if keySuccess == false then
				return false, string.format("[array] %*", keyErrMsg or "")
			end

			-- # is unreliable for sparse arrays
			-- Count upwards using ipairs to avoid false positives from the behavior of #
			local arraySize = 0

			for _ in ipairs(value) do
				arraySize += 1
			end

			for key in value do
				if key < 1 or key > arraySize then
					return false, string.format("[array] key %* must be sequential", tostring(key))
				end
			end

			local valueSuccess, valueErrMsg = valuesCheck(value)
			if not valueSuccess then
				return false, string.format("[array] %*", valueErrMsg or "")
			end

			return true
		end
	end

	--[[**
		ensures value is an array of a strict makeup and size

		@param check The check to compare all values with

		@returns A function that will return true iff the condition is passed
	**--]]
	function t.strictArray(...)
		local valueTypes = {...}
		assert(t.array(t.callback)(valueTypes))

		return function(value)
			local keySuccess, keyErrMsg = arrayKeysCheck(value)
			if keySuccess == false then
				return false, string.format("[strictArray] %*", keyErrMsg or "")
			end

			-- If there's more than the set array size, disallow
			if #valueTypes < #value then
				return false, string.format("[strictArray] Array size exceeds limit of %d", #valueTypes)
			end

			for idx, typeFn in valueTypes do
				local typeSuccess, typeErrMsg = typeFn(value[idx])
				if not typeSuccess then
					return false, string.format("[strictArray] Array index #%d - %*", idx, typeErrMsg)
				end
			end

			return true
		end
	end
end

do
	local callbackArray = t.array(t.callback)
	--[[**
		creates a union type

		@param ... The checks to union

		@returns A function that will return true iff the condition is passed
	**--]]
	function t_union(...)
		local checks = {...}
		assert(callbackArray(checks))

		return function(value)
			for _, check in checks do
				if check(value) then
					return true
				end
			end

			return false, "bad type for union"
		end
	end

	t.union = t_union

	--[[**
		Alias for t.union
	**--]]
	t.some = t.union

	--[[**
		creates an intersection type

		@param ... The checks to intersect

		@returns A function that will return true iff the condition is passed
	**--]]
	function t.intersection(...)
		local checks = {...}
		assert(callbackArray(checks))

		return function(value)
			for _, check in checks do
				local success, errMsg = check(value)
				if not success then
					return false, errMsg or ""
				end
			end

			return true
		end
	end

	--[[**
		Alias for t.intersection
	**--]]
	t.every = t.intersection
end

do
	local checkInterface = t.map(t.any, t.callback)
	--[[**
		ensures value matches given interface definition

		@param checkTable The interface definition

		@returns A function that will return true iff the condition is passed
	**--]]
	function t.interface(checkTable)
		assert(checkInterface(checkTable))
		return function(value)
			local tableSuccess, tableErrMsg = t.table(value)
			if tableSuccess == false then
				return false, tableErrMsg or ""
			end

			for key, check in checkTable do
				local success, errMsg = check(value[key])
				if success == false then
					return false, string.format("[interface] bad value for %*:\n\t%*", tostring(key), errMsg or "")
				end
			end

			return true
		end
	end

	--[[**
		ensures value matches given interface definition strictly

		@param checkTable The interface definition

		@returns A function that will return true iff the condition is passed
	**--]]
	function t.strictInterface(checkTable)
		assert(checkInterface(checkTable))
		return function(value)
			local tableSuccess, tableErrMsg = t.table(value)
			if tableSuccess == false then
				return false, tableErrMsg or ""
			end

			for key, check in checkTable do
				local success, errMsg = check(value[key])
				if success == false then
					return false, string.format("[interface] bad value for %*:\n\t%*", tostring(key), errMsg or "")
				end
			end

			for key in value do
				if not checkTable[key] then
					return false, string.format("[interface] unexpected field %q", tostring(key))
				end
			end

			return true
		end
	end
end

--[[**
	ensures value is an enum of the correct type

	@param enum The enum to check

	@returns A function that will return true iff the condition is passed
**--]]
function t.enum(enum)
	assert(t.Enum(enum))

	local enumValue = (function()
		local Enums = require("../Enums")
		for _, value in Enums do
			if value == enum then
				return value
			end
		end

		error("Failure???")
	end)()

	return function(value)
		local enumItemSuccess, enumItemErrMsg = t.userdata(value)
		if not enumItemSuccess then
			return false, enumItemErrMsg
		end

		local success, exception = enumValue.Cast(value)
		if success then
			return true
		else
			return false,
				string.format(
					"enum of %* expected, got enum of %* (error = %*)",
					tostring(enum),
					tostring(value),
					tostring(exception)
				)
		end
	end
end

do
	local checkWrap = t.tuple(t.callback, t.callback)

	--[[**
		wraps a callback in an assert with checkArgs

		@param callback The function to wrap
		@param checkArgs The function to use to check arguments in the assert

		@returns A function that first asserts using checkArgs and then calls callback
	**--]]
	function t.wrap(callback, checkArgs)
		assert(checkWrap(callback, checkArgs))
		return function(...)
			assert(checkArgs(...))
			return callback(...)
		end
	end
end

--[[**
	asserts a given check

	@param check The function to wrap with an assert

	@returns A function that simply wraps the given check in an assert
**--]]
function t.strict(check)
	return function(...)
		assert(check(...))
	end
end

return t
