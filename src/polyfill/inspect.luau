--!native
--!optimize 2
-- derived from these upstream sources:
-- https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/inspect.js

local HttpService = game:GetService("HttpService")

type Array<T> = {T}
-- local NULL = require(srcWorkspace.luaUtils.null)

-- Support for options partial implementation
-- see: https://nodejs.org/dist/latest-v16.x/docs/api/util.html#utilinspectobject-options
export type InspectOptions = {
	depth: number?,
}

type FormatOptions = {
	depth: number,
}

local MAX_ARRAY_LENGTH = 10
local DEFAULT_RECURSIVE_DEPTH = 2

-- deviation: pre-declare functions
local formatValue
local formatObjectValue
local formatArray
local formatObject
local getObjectTag

local function isArray(value: any)
	if type(value) ~= "table" then
		return false
	end

	if next(value) == nil then
		return true
	end

	local length = #value
	if length == 0 then
		return false
	end

	local count = 0
	local sum = 0

	for key in pairs(value) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 then
			return false
		end

		count += 1
		sum += key
	end

	return sum == count * (count + 1) / 2
end

--[[
 * Used to print values in error messages.
 ]]
local function inspect(value, options: InspectOptions?): string
	local inspectOptions: InspectOptions = options or {depth = DEFAULT_RECURSIVE_DEPTH}
	local depth = inspectOptions.depth or DEFAULT_RECURSIVE_DEPTH
	inspectOptions.depth = if depth >= 0 then depth else DEFAULT_RECURSIVE_DEPTH
	return formatValue(value, {}, inspectOptions :: FormatOptions)
end

local function isIndexKey(k, contiguousLength)
	return type(k) == "number"
		and k <= contiguousLength -- nothing out of bounds
		and 1 <= k -- nothing illegal for array indices
		and math.floor(k) == k -- no float keys
end

local function getTableLength(tbl)
	local length = 1
	local value = rawget(tbl, length)
	while value ~= nil do
		length += 1
		value = rawget(tbl, length)
	end

	return length - 1
end

local function sortKeysForPrinting(a: any, b)
	local typeofA = type(a)
	local typeofB = type(b)

	-- strings and numbers are sorted numerically/alphabetically
	if typeofA == typeofB and (typeofA == "number" or typeofA == "string") then
		return a < b
	end

	-- sort the rest by type name
	return typeofA < typeofB
end

local function getFragmentedKeys(tbl)
	local keys = {}
	local keysLength = 0
	local tableLength = getTableLength(tbl)
	for key in tbl do
		if not isIndexKey(key, tableLength) then
			keysLength += 1
			keys[keysLength] = key
		end
	end

	table.sort(keys, sortKeysForPrinting)
	return keys, keysLength, tableLength
end

function formatValue(value, seenValues, options: FormatOptions)
	local valueType = typeof(value)
	if valueType == "string" then
		return HttpService:JSONEncode(value)
	end

	if valueType == "number" then
		if value ~= value then
			return "NaN"
		end

		if value == math.huge then
			return "Infinity"
		end

		if value == -math.huge then
			return "-Infinity"
		end

		return `{value}`
	end

	if valueType == "function" then
		local result = "[function"
		local functionName = debug.info(value :: (any) -> any, "n")
		if functionName ~= nil and functionName ~= "" then
			result ..= " " .. functionName
		end

		return result .. "]"
	end

	if valueType == "table" then
		-- ROBLOX TODO: parameterize inspect with the library-specific NULL sentinel. maybe function generics?
		-- if value == NULL then
		-- 	return 'null'
		-- end
		return formatObjectValue(value, seenValues, options)
	end

	return `{value}`
end

function formatObjectValue(value, previouslySeenValues, options: FormatOptions)
	if table.find(previouslySeenValues, value) ~= nil then
		return "[Circular]"
	end

	local seenValues = {table.unpack(previouslySeenValues)}
	table.insert(seenValues, value)

	if type(value.toJSON) == "function" then
		local jsonValue = value:toJSON(value)

		if jsonValue ~= value then
			return if type(jsonValue) == "string" then jsonValue else formatValue(jsonValue, seenValues, options)
		end
	end

	if isArray(value) then
		return formatArray(value, seenValues, options)
	end

	return formatObject(value, seenValues, options)
end

function formatObject(object, seenValues, options: FormatOptions)
	local result = ""
	local metatable = getmetatable(object)
	if metatable and rawget(metatable, "__tostring") then
		return `{object}`
	end

	local fragmentedKeys, fragmentedKeysLength, keysLength = getFragmentedKeys(object)

	if keysLength == 0 and fragmentedKeysLength == 0 then
		result ..= "{}"
		return result
	end

	if #seenValues > options.depth then
		result ..= "[" .. getObjectTag(object) .. "]"
		return result
	end

	local properties = {}
	for index = 1, keysLength do
		local value = formatValue(object[index], seenValues, options)

		table.insert(properties, value)
	end

	for index = 1, fragmentedKeysLength do
		local key = fragmentedKeys[index]
		local value = formatValue(object[key], seenValues, options)

		table.insert(properties, key .. ": " .. value)
	end

	result ..= "{ " .. table.concat(properties, ", ") .. " }"
	return result
end

function formatArray(array: Array<any>, seenValues: Array<any>, options: FormatOptions): string
	local length = #array
	if length == 0 then
		return "[]"
	end

	if #seenValues > options.depth then
		return "[Array]"
	end

	local len = math.min(MAX_ARRAY_LENGTH, length)
	local remaining = length - len
	local items = {}

	for index = 1, len do
		items[index] = formatValue(array[index], seenValues, options)
	end

	if remaining == 1 then
		table.insert(items, "... 1 more item")
	elseif remaining > 1 then
		table.insert(items, `... {remaining} more items`)
	end

	return `[{table.concat(items, ", ")}]`
end

function getObjectTag(_object): string
	return "Object"
end

return table.freeze({
	inspect = inspect,
	default = inspect,
})
