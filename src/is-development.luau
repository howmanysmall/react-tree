--!native
--!optimize 2
--!strict

local function isDevelopment()
	return _G.__DEV__
end

return isDevelopment
