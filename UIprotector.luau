local globalEnv = (getgenv and getgenv()) or _G or {}
local sharedEnv = rawget(_G, "shared")
local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)

if cacheHost then
	local cached = rawget(cacheHost, "__lt_ui_protector")
	if type(cached) == "table" then
		return cached
	end
end

local protector = {}
local serviceResolverUrl = "https://ltseverydayyou.github.io/ServiceResolver.luau"
local __lt = nil

local function getCachedServiceResolver()
	if type(globalEnv) == "table" then
		local runtimeResolver = rawget(globalEnv, "__NAServiceResolver")
		if type(runtimeResolver) == "table" then
			return runtimeResolver
		end
	end

	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end

	return nil
end

local function loadServiceResolver()
	local cached = getCachedServiceResolver()
	if type(cached) == "table" then
		return cached
	end

	local loader = loadstring or load
	if type(loader) ~= "function" or not game or type(game.HttpGet) ~= "function" then
		return nil
	end

	local okSource, source = pcall(function()
		return game:HttpGet(serviceResolverUrl)
	end)
	if not okSource or type(source) ~= "string" or source == "" then
		return nil
	end

	local chunk = loader(source, "@ServiceResolver.luau")
	if type(chunk) ~= "function" then
		return nil
	end

	local okLoaded, loaded = pcall(chunk)
	if okLoaded and type(loaded) == "table" then
		return loaded
	end

	return nil
end

__lt = loadServiceResolver()
protector.serviceResolver = __lt

local function isInstance(value)
	return typeof(value) == "Instance"
end

local function cloneRef(value)
	if __lt and type(__lt.cv) == "function" then
		local ok, cloned = pcall(__lt.cv, value)
		if ok and cloned ~= nil then
			return cloned
		end
	end
	if type(cloneref) == "function" and isInstance(value) then
		local ok, cloned = pcall(cloneref, value)
		if ok and cloned ~= nil then
			return cloned
		end
	end
	return value
end

local function getService(name)
	if __lt then
		if type(__lt.cs) == "function" then
			local ok, service = pcall(__lt.cs, name, __lt.cr)
			if ok and isInstance(service) then
				return service
			end
		end
		if type(__lt.gs) == "function" then
			local ok, service = pcall(__lt.gs, name)
			if ok and isInstance(service) then
				return cloneRef(service)
			end
		end
	end

	local ok, service = pcall(function()
		return game:GetService(name)
	end)
	if ok and isInstance(service) then
		return cloneRef(service)
	end
	return nil
end

local function tryCall(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(fn, ...)
	if ok and result ~= nil then
		return result
	end
	return nil
end

function protector.huiGrabber()
	local hidden = tryCall(gethui)
		or tryCall(gethiddenui)
		or tryCall(gethiddengui)
		or tryCall(get_hidden_ui)
		or tryCall(get_hidden_gui)
		or nil
	return cloneRef(hidden)
end

function protector.resolveParent(options)
	options = type(options) == "table" and options or {}

	local fromResolver = tryCall(options.parentResolver)
	if isInstance(fromResolver) then
		return fromResolver
	end

	local hidden = protector.huiGrabber()
	if isInstance(hidden) then
		return hidden
	end

	local coreGui = cloneRef(options.coreGui)
	if not isInstance(coreGui) then
		coreGui = getService("CoreGui")
	end

	if isInstance(coreGui) then
		local screenGui = tryCall(function()
			return coreGui:FindFirstChildWhichIsA("ScreenGui")
		end)
		if isInstance(screenGui) then
			return screenGui
		end
		return coreGui
	end

	local players = cloneRef(options.players)
	if not isInstance(players) then
		players = getService("Players")
	end

	local localPlayer = isInstance(options.localPlayer) and cloneRef(options.localPlayer) or (isInstance(players) and cloneRef(players.LocalPlayer) or nil)
	local playerGui = isInstance(localPlayer) and tryCall(function()
		return localPlayer:FindFirstChildWhichIsA("PlayerGui")
	end) or nil

	if isInstance(playerGui) then
		return playerGui
	end

	return nil
end

function protector.randomString()
	local httpService = getService("HttpService")
	if httpService and httpService.GenerateGUID then
		return httpService:GenerateGUID(false)
	end

	local length = math.random(10, 20)
	local result = {}
	local glitchMarks = {"̶", "̷", "̸", "̹", "̺", "̻", "͓", "͔", "͘", "͜", "͞", "͟", "͢"}

	for i = 1, length do
		result[#result + 1] = string.char(math.random(32, 126))
		if math.random() < 0.5 then
			local numGlitches = math.random(1, 4)
			for _ = 1, numGlitches do
				result[#result + 1] = glitchMarks[math.random(#glitchMarks)]
			end
		end
	end

	if math.random() < 0.3 and utf8 and utf8.char then
		result[#result + 1] = utf8.char(math.random(0x0300, 0x036F))
	end
	if math.random() < 0.1 then
		result[#result + 1] = "\0"
	end
	if math.random() < 0.1 then
		result[#result + 1] = string.rep("​", math.random(5, 20))
	end
	if math.random() < 0.2 and utf8 and utf8.char then
		result[#result + 1] = utf8.char(0x202E)
	end

	return table.concat(result)
end

function protector.protectName(instance, property)
	if not isInstance(instance) then
		return nil
	end

	local protectedName = protector.randomString() or "\0"
	pcall(function()
		if property then
			instance[property] = protectedName
		else
			instance.Name = protectedName
		end
	end)
	pcall(function()
		instance.Archivable = false
	end)

	return instance
end

function protector.protectUI(gui, options)
	if not isInstance(gui) then
		return nil
	end

	options = type(options) == "table" and options or {}
	local target = protector.resolveParent(options)
	if not isInstance(target) then
		return nil
	end

	local maxDisplayOrder = tonumber(options.maxDisplayOrder) or 0x7FFFFFFF
	local protectedName = protector.randomString() or "\0"

	pcall(function()
		gui.Archivable = false
	end)
	pcall(function()
		gui.Name = protectedName
	end)
	pcall(function()
		gui.Parent = target
	end)

	local props = {
		Parent = target,
		Archivable = false,
	}

	if gui:IsA("ScreenGui") then
		props.ZIndexBehavior = Enum.ZIndexBehavior.Global
		props.DisplayOrder = maxDisplayOrder
		props.ResetOnSpawn = false
		props.IgnoreGuiInset = true
	end

	for prop, val in pairs(props) do
		pcall(function()
			gui:GetPropertyChangedSignal(prop):Connect(function()
				if gui[prop] ~= val then
					pcall(function()
						gui[prop] = val
					end)
				end
			end)
		end)
	end

	pcall(function()
		gui.AncestryChanged:Connect(function()
			if gui.Parent ~= target then
				pcall(function()
					gui.Parent = target
				end)
			end
		end)
	end)

	local taskLib = task
	local spawnFn = taskLib and (taskLib.spawn or taskLib.defer) or spawn
	local waitFn = taskLib and taskLib.wait or wait
	local function watchdog()
		while gui and gui.Parent do
			waitFn(tonumber(options.interval) or 0.75)
			for prop, val in pairs(props) do
				if gui[prop] ~= val then
					pcall(function()
						gui[prop] = val
					end)
				end
			end
		end
	end

	if type(spawnFn) == "function" then
		spawnFn(watchdog)
	else
		coroutine.wrap(watchdog)()
	end

	return gui
end

if cacheHost then
	cacheHost.__lt_ui_protector = protector
end

return protector
