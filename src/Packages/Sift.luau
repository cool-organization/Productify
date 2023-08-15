--!optimize 2
--!strict

local Sift = {}

function Sift.equalObjects(...: {[any]: any})
	local firstItem = select(1, ...)

	for index = 2, select("#", ...) do
		if firstItem ~= select(index, ...) then
			return false
		end
	end

	return true
end

Sift.Array = {}

do
	function Sift.Array.filter<T>(Array: {T}, Filter: (Value: T) -> boolean)
		local New = {}
		local Length = 0

		for _, Value in Array do
			if Filter(Value) then
				Length += 1
				New[Length] = Value
			end
		end

		return New
	end
end

Sift.Dictionary = {}

do
	local function CopyDeep<T>(Table: T): T
		assert(type(Table) == "table", `Invalid argument #1 to 'CopyDeep' (expected table, got {typeof(Table)})`)

		local New = table.clone(Table) :: any
		for Key, Value in Table do
			if type(Value) == "table" then
				New[Key] = CopyDeep(Value)
			end
		end

		return New
	end
	Sift.Dictionary.copyDeep = CopyDeep

	local function compare(a, b)
		if type(a) ~= "table" or type(b) ~= "table" then
			return a == b
		end

		for key, value in a do
			if b[key] ~= value then
				return false
			end
		end

		for key, value in b do
			if a[key] ~= value then
				return false
			end
		end

		return true
	end

	function Sift.Dictionary.equals(...: {[any]: any}): boolean
		if Sift.equalObjects(...) then
			return true
		end

		local totalArgs = select("#", ...)
		local firstItem = select(1, ...)

		for index = 2, totalArgs do
			local item = select(index, ...)

			if not compare(firstItem, item) then
				return false
			end
		end

		return true
	end
end

table.freeze(Sift.Array)
table.freeze(Sift.Dictionary)
return table.freeze(Sift)
