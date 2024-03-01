--!native
--!optimize 2

type Function = (...any) -> any

export type Error = {name: string, message: string, stack: string?}
type Error_private = Error & {__stack: string?}

local Error = {}

local DEFAULT_NAME = "Error"
Error.__index = Error
Error.__tostring = function(self)
	-- Luau FIXME: I can't cast to Error or Object here: Type 'Object' could not be converted into '{ @metatable *unknown*, {|  |} }'
	return getmetatable(Error :: any).__tostring(self)
end

function Error.instanceof(value)
	return type(value) == "table" and getmetatable(value) == Error
end

-- ROBLOX NOTE: extracted __createError function so that both Error.new() and Error() can capture the stack trace at the same depth
local function __createError(message: string?): Error
	local self: Error = setmetatable({
		name = DEFAULT_NAME;
		message = message or "";
	}, Error) :: any

	Error.__captureStackTrace(self :: Error_private, 4)
	return self
end

function Error.new(message: string?): Error
	return __createError(message)
end

function Error.captureStackTrace(err: Error, options: Function?)
	Error.__captureStackTrace(err :: Error_private, 3, options)
end

function Error.__captureStackTrace(self: Error_private, level: number, options: Function?)
	if type(options) == "function" then
		local stack = debug.traceback(nil, level)
		local functionName: string = debug.info(options, "n")
		local sourceFilePath: string = debug.info(options, "s")

		local escapedSourceFilePath = string.gsub(sourceFilePath, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
		local stacktraceLinePattern = `{escapedSourceFilePath}:%d* function {functionName}`
		local start = string.find(stack, stacktraceLinePattern)
		local finish = nil

		if start ~= nil then
			start, finish = string.find(stack, "\n", start + 1)
		end

		if finish ~= nil then
			stack = string.sub(stack, finish + 1)
		end

		self.__stack = stack
	else
		self.__stack = debug.traceback(nil, level)
	end

	Error.__recalculateStacktrace(self)
end

function Error.__recalculateStacktrace(self: Error_private)
	local message = self.message
	local name = self.name or DEFAULT_NAME

	local errName = `{name}{if message ~= nil and message ~= "" then `: {message}` else ""}`
	local stack = if self.__stack then self.__stack else ""

	self.stack = `{errName}\n{stack}`
end

return table.freeze({
	default = setmetatable(Error, {
		__call = function(_, ...)
			return __createError(...)
		end;

		__tostring = function(self)
			if self.name ~= nil then
				if self.message and self.message ~= "" then
					return `{self.name}: {self.message}`
				end

				return `{self.name}`
			end

			return DEFAULT_NAME
		end;
	});
})
