local okEnv, globalEnv = pcall(function()
	if type(getgenv) == "function" then
		return getgenv()
	end
end)

if not okEnv or type(globalEnv) ~= "table" then
	globalEnv = type(_G) == "table" and _G or {}
end

local sharedEnv
pcall(function()
	sharedEnv = shared
end)

if type(sharedEnv) ~= "table" then
	pcall(function()
		sharedEnv = rawget(_G, "shared")
	end)
end

local cacheHost = type(sharedEnv) == "table" and sharedEnv or globalEnv
local cached = type(cacheHost) == "table" and rawget(cacheHost, "__lt_ui_protector")

if type(cached) == "table" then
	if type(cached.installGetHuiOverride) == "function" then
		pcall(cached.installGetHuiOverride)
	end
	return cached
end

local protector = {}

local state = {
	folder = nil,
	screen = nil,
	raw = nil,
	mode = "folder",
	heartbeat = nil,
	installed = false,
	last = 0,
	rate = 0.35,
	connections = setmetatable({}, { __mode = "k" }),
	tracked = setmetatable({}, { __mode = "k" }),
	locked = setmetatable({}, { __mode = "k" }),
	descWatching = setmetatable({}, { __mode = "k" }),
	funcCache = {},
	localFuncs = {},
	nativeHuiFns = {},
}

pcall(function()
	state.localFuncs.gethui = gethui
	state.localFuncs.gethiddenui = gethiddenui
	state.localFuncs.gethiddengui = gethiddengui
	state.localFuncs.get_hidden_ui = get_hidden_ui
	state.localFuncs.get_hidden_gui = get_hidden_gui
	state.localFuncs.cloneref = cloneref
	state.localFuncs.compareinstances = compareinstances
	state.localFuncs.setreadonly = setreadonly
	state.localFuncs.isreadonly = isreadonly
	state.localFuncs.protect_gui = protect_gui
	state.localFuncs.protectgui = protectgui
	state.localFuncs.protect_ui = protect_ui
	state.localFuncs.protectui = protectui
	state.localFuncs.getrenv = getrenv
end)

local function isInstance(value)
	return typeof(value) == "Instance"
end

local function safeCall(fn, ...)
	if type(fn) ~= "function" then
		return false, nil
	end
	return pcall(fn, ...)
end

local function tryCall(fn, ...)
	local ok, result = safeCall(fn, ...)
	if ok then
		return result
	end
	return nil
end

local function getFunc(name)
	local value = state.localFuncs[name]

	if type(value) == "function" then
		return value
	end

	if type(state.funcCache[name]) == "function" then
		return state.funcCache[name]
	end

	if type(globalEnv) == "table" then
		value = rawget(globalEnv, name)
		if type(value) == "function" then
			state.funcCache[name] = value
			return value
		end
	end

	pcall(function()
		if type(_G) == "table" then
			value = rawget(_G, name)
		end
	end)

	if type(value) == "function" then
		state.funcCache[name] = value
		return value
	end

	local getRenv = state.localFuncs.getrenv

	if type(getRenv) ~= "function" and type(globalEnv) == "table" then
		getRenv = rawget(globalEnv, "getrenv")
	end

	if type(getRenv) == "function" then
		local renv = tryCall(getRenv)
		if type(renv) == "table" then
			value = rawget(renv, name)
			if type(value) == "function" then
				state.funcCache[name] = value
				return value
			end
		end
	end

	return nil
end

local function captureFunc(name)
	local value = state.localFuncs[name]

	if type(value) == "function" then
		return value
	end

	if type(globalEnv) == "table" then
		value = rawget(globalEnv, name)
		if type(value) == "function" then
			return value
		end
	end

	pcall(function()
		if type(_G) == "table" then
			value = rawget(_G, name)
		end
	end)

	if type(value) == "function" then
		return value
	end

	return nil
end

state.nativeHuiFns.gethui = captureFunc("gethui")
state.nativeHuiFns.gethiddenui = captureFunc("gethiddenui")
state.nativeHuiFns.gethiddengui = captureFunc("gethiddengui")
state.nativeHuiFns.get_hidden_ui = captureFunc("get_hidden_ui")
state.nativeHuiFns.get_hidden_gui = captureFunc("get_hidden_gui")

function protector.has(name)
	return type(getFunc(name)) == "function"
end

function protector.getFunction(name)
	return getFunc(name)
end

local function cloneRef(value)
	local fn = getFunc("cloneref")

	if type(fn) == "function" and isInstance(value) then
		local ok, result = pcall(fn, value)
		if ok and result ~= nil then
			return result
		end
	end

	return value
end

local function getService(name)
	local ok, service = pcall(function()
		local fn = getFunc("cloneref")
		if type(fn) == "function" then
			return fn(game:GetService(name))
		end
		return game:GetService(name)
	end)

	if ok and isInstance(service) then
		return service
	end

	return nil
end

local function isA(value, className)
	if not isInstance(value) then
		return false
	end

	local ok, result = pcall(function()
		return value:IsA(className)
	end)

	return ok and result == true
end

local function sameInstance(a, b)
	if a == b then
		return true
	end

	local fn = getFunc("compareinstances")

	if type(fn) == "function" and isInstance(a) and isInstance(b) then
		local ok, result = pcall(fn, a, b)
		if ok then
			return result == true
		end
	end

	return false
end

local function getProperty(instance, property)
	local ok, result = pcall(function()
		return instance[property]
	end)

	if ok then
		return result
	end

	return nil
end

local function setProperty(instance, property, value)
	pcall(function()
		instance[property] = value
	end)
end

local function addConnection(instance, connection)
	if not connection then
		return
	end

	local list = state.connections[instance]
	if not list then
		list = {}
		state.connections[instance] = list
	end

	list[#list + 1] = connection
end

local function getEnum(enumName, itemName)
	local ok, result = pcall(function()
		return Enum[enumName][itemName]
	end)

	if ok then
		return result
	end

	return nil
end

local function getPath(instance)
	if not isInstance(instance) then
		return nil
	end

	local ok, result = pcall(function()
		return instance:GetFullName()
	end)

	if ok then
		return result
	end

	return instance.ClassName
end

local function trackedCount()
	local count = 0

	for instance in pairs(state.tracked) do
		if isInstance(instance) then
			count += 1
		end
	end

	return count
end

function protector.randomString()
	local httpService = getService("HttpService")

	if isInstance(httpService) and httpService.GenerateGUID then
		local ok, result = pcall(function()
			return httpService:GenerateGUID(false)
		end)

		if ok and type(result) == "string" and result ~= "" then
			local prefix = math.random(1, 3) == 1 and "\0" or ""
			local suffix = math.random(1, 3) == 1 and "​" or ""
			return prefix .. result .. suffix
		end
	end

	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local length = math.random(18, 32)
	local result = {}

	for i = 1, length do
		local index = math.random(1, #chars)
		result[i] = chars:sub(index, index)
	end

	if math.random(1, 3) == 1 then
		result[#result + 1] = "\0"
	end

	if math.random(1, 3) == 1 then
		result[#result + 1] = "​"
	end

	return table.concat(result)
end

function protector.nativeProtect(instance)
	if not isInstance(instance) then
		return instance
	end

	local names = {
		"protect_gui",
		"protectgui",
		"protect_ui",
		"protectui",
	}

	for i = 1, #names do
		local fn = getFunc(names[i])
		if type(fn) == "function" then
			pcall(fn, instance)
		end
	end

	return instance
end

function protector.setTableReadonly(tbl, stateValue)
	if type(tbl) ~= "table" then
		return tbl
	end

	local fn = getFunc("setreadonly")

	if type(fn) == "function" then
		pcall(fn, tbl, stateValue ~= false)
	end

	return tbl
end

local function rawHui()
	local funcs = {
		state.nativeHuiFns.gethui,
		state.nativeHuiFns.gethiddenui,
		state.nativeHuiFns.gethiddengui,
		state.nativeHuiFns.get_hidden_ui,
		state.nativeHuiFns.get_hidden_gui,
	}

	for i = 1, #funcs do
		local result = cloneRef(tryCall(funcs[i]))
		if isInstance(result) and not sameInstance(result, state.folder) and not sameInstance(result, state.screen) then
			state.raw = result
			return result
		end
	end

	return state.raw
end

function protector.rawHuiGrabber()
	return rawHui()
end

local function huiKind(instance)
	if not isInstance(instance) then
		return nil
	end

	if isA(instance, "BasePlayerGui") then
		return "root"
	end

	if isA(instance, "Folder") then
		return "folder"
	end

	if isA(instance, "ScreenGui") then
		return "screen"
	end

	local className = instance.ClassName

	if className == "CoreGui" or className == "PlayerGui" or className == "StarterGui" then
		return "root"
	end

	return nil
end

function protector.getRawHuiKind()
	return huiKind(rawHui())
end

function protector.getBaseParent()
	local coreGui = getService("CoreGui")

	if isInstance(coreGui) then
		local robloxGui = tryCall(function()
			return coreGui:FindFirstChild("RobloxGui")
		end)

		if isInstance(robloxGui) then
			return robloxGui
		end

		return coreGui
	end

	local players = getService("Players")
	local localPlayer = isInstance(players) and cloneRef(players.LocalPlayer) or nil

	if isInstance(localPlayer) then
		local playerGui = tryCall(function()
			return localPlayer:FindFirstChildWhichIsA("PlayerGui")
		end)

		if isInstance(playerGui) then
			return playerGui
		end
	end

	return nil
end

local function startWatchdog()
	if state.heartbeat then
		return
	end

	local runService = getService("RunService")
	if not (isInstance(runService) and runService.Heartbeat) then
		return
	end

	state.heartbeat = runService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - state.last < state.rate then
			return
		end

		state.last = now

		local active = false

		for instance, config in pairs(state.tracked) do
			if not isInstance(instance) or config.dead then
				state.tracked[instance] = nil
				state.locked[instance] = nil
				state.descWatching[instance] = nil
			else
				active = true

				for property, value in pairs(config.properties) do
					local current = getProperty(instance, property)

					if property == "Parent" then
						if isInstance(value) and not sameInstance(current, value) then
							setProperty(instance, property, value)
						end
					elseif current ~= value then
						setProperty(instance, property, value)
					end
				end
			end
		end

		if not active and state.heartbeat then
			pcall(function()
				state.heartbeat:Disconnect()
			end)

			state.heartbeat = nil
		end
	end)
end

function protector.lockInstance(instance, properties)
	if not isInstance(instance) or type(properties) ~= "table" then
		return instance
	end

	for property, value in pairs(properties) do
		setProperty(instance, property, value)
	end

	state.tracked[instance] = {
		properties = properties,
		dead = false,
	}

	if not state.locked[instance] then
		state.locked[instance] = true

		for property in pairs(properties) do
			local ok, signal = pcall(function()
				return instance:GetPropertyChangedSignal(property)
			end)

			if ok and signal then
				addConnection(instance, signal:Connect(function()
					local config = state.tracked[instance]
					if not config or config.dead then
						return
					end

					local value = config.properties[property]
					local current = getProperty(instance, property)

					if property == "Parent" then
						if isInstance(value) and not sameInstance(current, value) then
							setProperty(instance, property, value)
						end
					elseif current ~= value then
						setProperty(instance, property, value)
					end
				end))
			end
		end

		pcall(function()
			addConnection(instance, instance.AncestryChanged:Connect(function()
				local config = state.tracked[instance]
				if not config or config.dead then
					return
				end

				local parent = config.properties.Parent
				if isInstance(parent) and not sameInstance(instance.Parent, parent) then
					setProperty(instance, "Parent", parent)
				end
			end))
		end)

		pcall(function()
			addConnection(instance, instance.Destroying:Connect(function()
				local config = state.tracked[instance]
				if config then
					config.dead = true
				end

				state.tracked[instance] = nil
				state.locked[instance] = nil
				state.descWatching[instance] = nil
			end))
		end)
	end

	startWatchdog()
	return instance
end

function protector.harden(instance, options)
	if not isInstance(instance) then
		return instance
	end

	options = type(options) == "table" and options or {}

	pcall(function()
		instance.Archivable = false
	end)

	if options.rename then
		pcall(function()
			instance.Name = protector.randomString()
		end)
	end

	if options.deep then
		local descendants = tryCall(function()
			return instance:GetDescendants()
		end)

		if type(descendants) == "table" then
			for i = 1, #descendants do
				local descendant = descendants[i]
				if isInstance(descendant) then
					pcall(function()
						descendant.Archivable = false
					end)

					if options.rename then
						pcall(function()
							descendant.Name = protector.randomString()
						end)
					end
				end
			end
		end
	end

	if options.watch and not state.descWatching[instance] then
		state.descWatching[instance] = true

		pcall(function()
			addConnection(instance, instance.DescendantAdded:Connect(function(descendant)
				if not isInstance(descendant) then
					return
				end

				pcall(function()
					descendant.Archivable = false
				end)

				if options.rename then
					pcall(function()
						descendant.Name = protector.randomString()
					end)
				end
			end))
		end)
	end

	return instance
end

local function configureScreen(screenGui, parent, name, lockName)
	local properties = {
		Parent = parent,
		Archivable = false,
		Enabled = true,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2147483647,
	}

	if lockName then
		properties.Name = type(name) == "string" and name ~= "" and name or protector.randomString()
	end

	local zIndexBehavior = getEnum("ZIndexBehavior", "Global")
	if zIndexBehavior then
		properties.ZIndexBehavior = zIndexBehavior
	end

	local screenInsets = getEnum("ScreenInsets", "None")
	if screenInsets then
		properties.ScreenInsets = screenInsets
	end

	local safeAreaCompatibility = getEnum("SafeAreaCompatibility", "None")
	if safeAreaCompatibility then
		properties.SafeAreaCompatibility = safeAreaCompatibility
	end

	pcall(function()
		screenGui.ClipToDeviceSafeArea = false
	end)

	pcall(function()
		screenGui.OnTopOfCoreBlur = true
	end)

	protector.nativeProtect(screenGui)
	protector.lockInstance(screenGui, properties)

	return screenGui
end

local function makeFolder(parent, name)
	if not isInstance(parent) then
		return nil
	end

	local folder = Instance.new("Folder")

	protector.nativeProtect(folder)

	protector.lockInstance(folder, {
		Name = type(name) == "string" and name ~= "" and name or protector.randomString(),
		Parent = parent,
		Archivable = false,
	})

	return folder
end

function protector.getHui()
	local raw = rawHui()
	local kind = huiKind(raw)

	if kind then
		return raw
	end

	local parent = protector.getBaseParent()
	if isInstance(parent) then
		return parent
	end

	return nil
end

function protector.getScreenGui(name)
	local hui = protector.getHui()
	local kind = huiKind(hui)

	if kind == "screen" then
		state.screen = hui

		local parent = getProperty(hui, "Parent")
		if isInstance(parent) then
			configureScreen(hui, parent, nil, false)
		else
			protector.nativeProtect(hui)
			protector.harden(hui, {
				deep = false,
				watch = true,
			})
		end

		return hui
	end

	if not isInstance(hui) then
		return nil
	end

	if isInstance(state.screen) and sameInstance(state.screen.Parent, hui) then
		return state.screen
	end

	local screenGui = Instance.new("ScreenGui")
	state.screen = screenGui

	configureScreen(screenGui, hui, name, true)

	protector.harden(screenGui, {
		deep = false,
		watch = true,
	})

	return screenGui
end

function protector.adoptScreenGui(sourceGui, options)
	if not isInstance(sourceGui) or not isA(sourceGui, "ScreenGui") then
		return nil
	end

	options = type(options) == "table" and options or {}

	local targetGui = protector.getScreenGui()
	if not isInstance(targetGui) then
		return nil
	end

	local children = tryCall(function()
		return sourceGui:GetChildren()
	end)

	if type(children) == "table" then
		for i = 1, #children do
			pcall(function()
				children[i].Parent = targetGui
			end)
		end
	end

	if not state.descWatching[sourceGui] then
		state.descWatching[sourceGui] = true

		pcall(function()
			addConnection(sourceGui, sourceGui.ChildAdded:Connect(function(child)
				pcall(function()
					child.Parent = targetGui
				end)
			end))
		end)
	end

	protector.harden(sourceGui, {
		deep = false,
		watch = true,
		rename = options.rename == true,
	})

	return targetGui
end

function protector.getCustomHui(name)
	local hui = protector.getHui()
	local kind = huiKind(hui)

	if kind == "folder" then
		return hui
	end

	if kind == "screen" then
		if isInstance(state.folder) and sameInstance(state.folder.Parent, hui) then
			return state.folder
		end

		state.folder = makeFolder(hui, name)

		if isInstance(state.folder) then
			pcall(function()
				addConnection(state.folder, state.folder.ChildAdded:Connect(function(child)
					if isInstance(child) and isA(child, "ScreenGui") then
						protector.adoptScreenGui(child)
					end
				end))
			end)
		end

		return state.folder
	end

	if kind == "root" then
		if isInstance(state.folder) and sameInstance(state.folder.Parent, hui) then
			return state.folder
		end

		state.folder = makeFolder(hui, name)
		return state.folder
	end

	local parent = protector.getBaseParent()
	if not isInstance(parent) then
		return nil
	end

	if isInstance(state.folder) and sameInstance(state.folder.Parent, parent) then
		return state.folder
	end

	state.folder = makeFolder(parent, name)
	return state.folder
end

function protector.resolveParent(options)
	options = type(options) == "table" and options or {}

	local fromResolver = tryCall(options.parentResolver)
	if isInstance(fromResolver) then
		return fromResolver
	end

	if isInstance(options.parent) then
		return cloneRef(options.parent)
	end

	local mode = type(options.mode) == "string" and options.mode:lower() or state.mode

	if mode == "screen" then
		return protector.getScreenGui()
	end

	return protector.getCustomHui() or protector.getBaseParent()
end

function protector.parent(mode)
	mode = type(mode) == "string" and mode:lower() or state.mode

	if mode == "screen" then
		return protector.getScreenGui()
	end

	return protector.getCustomHui()
end

function protector.protectUI(gui, options)
	if not isInstance(gui) then
		return nil
	end

	options = type(options) == "table" and options or {}

	local parent = isInstance(options.parent) and cloneRef(options.parent) or nil

	if not isInstance(parent) then
		if isA(gui, "ScreenGui") then
			parent = protector.parent(options.mode or state.mode)
		else
			parent = protector.getScreenGui()
		end
	end

	if not isInstance(parent) then
		return nil
	end

	protector.nativeProtect(gui)

	local properties = {
		Parent = parent,
		Archivable = false,
	}

	if not options.keepName then
		properties.Name = type(options.name) == "string" and options.name ~= "" and options.name or protector.randomString()
	end

	if isA(gui, "ScreenGui") then
		properties.Enabled = true
		properties.ResetOnSpawn = false
		properties.IgnoreGuiInset = true
		properties.DisplayOrder = tonumber(options.displayOrder) or 2147483647

		local zIndexBehavior = getEnum("ZIndexBehavior", "Global")
		if zIndexBehavior then
			properties.ZIndexBehavior = zIndexBehavior
		end

		local screenInsets = getEnum("ScreenInsets", "None")
		if screenInsets then
			properties.ScreenInsets = screenInsets
		end

		local safeAreaCompatibility = getEnum("SafeAreaCompatibility", "None")
		if safeAreaCompatibility then
			properties.SafeAreaCompatibility = safeAreaCompatibility
		end

		pcall(function()
			gui.ClipToDeviceSafeArea = false
		end)

		pcall(function()
			gui.OnTopOfCoreBlur = true
		end)
	end

	protector.lockInstance(gui, properties)

	if options.harden ~= false then
		protector.harden(gui, {
			deep = options.deep == true,
			watch = options.watch ~= false,
			rename = options.rename == true,
		})
	end

	return gui
end

function protector.protectName(instance, property)
	if not isInstance(instance) then
		return nil
	end

	local protectedName = protector.randomString()

	pcall(function()
		instance[property or "Name"] = protectedName
	end)

	pcall(function()
		instance.Archivable = false
	end)

	return instance
end

function protector.huiGrabber()
	return protector.parent()
end

function protector.installGetHuiOverride(mode)
	if type(mode) == "table" then
		mode = mode.mode
	end

	mode = type(mode) == "string" and mode:lower() or state.mode

	if mode ~= "screen" then
		mode = "folder"
	end

	state.mode = mode

	local function customGetHui()
		return protector.parent(state.mode)
	end

	local installed = false

	pcall(function()
		gethui = customGetHui
		gethiddenui = customGetHui
		gethiddengui = customGetHui
		get_hidden_ui = customGetHui
		get_hidden_gui = customGetHui
		installed = true
	end)

	local function applyToEnv(env)
		if type(env) ~= "table" then
			return false
		end

		rawset(env, "gethui", customGetHui)
		rawset(env, "gethiddenui", customGetHui)
		rawset(env, "gethiddengui", customGetHui)
		rawset(env, "get_hidden_ui", customGetHui)
		rawset(env, "get_hidden_gui", customGetHui)

		return true
	end

	local okGlobal = pcall(applyToEnv, globalEnv)
	local okG = pcall(applyToEnv, _G)

	state.installed = installed or okGlobal or okG
	protector.getHuiOverrideInstalled = state.installed

	return state.installed
end

function protector.install(mode)
	return protector.installGetHuiOverride(mode)
end

function protector.restore()
	local native = state.nativeHuiFns

	pcall(function()
		gethui = native.gethui
		gethiddenui = native.gethiddenui
		gethiddengui = native.gethiddengui
		get_hidden_ui = native.get_hidden_ui
		get_hidden_gui = native.get_hidden_gui
	end)

	local function applyToEnv(env)
		if type(env) ~= "table" then
			return
		end

		rawset(env, "gethui", native.gethui)
		rawset(env, "gethiddenui", native.gethiddenui)
		rawset(env, "gethiddengui", native.gethiddengui)
		rawset(env, "get_hidden_ui", native.get_hidden_ui)
		rawset(env, "get_hidden_gui", native.get_hidden_gui)
	end

	pcall(applyToEnv, globalEnv)
	pcall(applyToEnv, _G)

	state.installed = false
	protector.getHuiOverrideInstalled = false
end

function protector.cleanup(instance)
	if isInstance(instance) then
		local list = state.connections[instance]

		if list then
			for i = 1, #list do
				pcall(function()
					list[i]:Disconnect()
				end)

				list[i] = nil
			end
		end

		state.connections[instance] = nil
		state.tracked[instance] = nil
		state.locked[instance] = nil
		state.descWatching[instance] = nil

		if trackedCount() <= 0 and state.heartbeat then
			pcall(function()
				state.heartbeat:Disconnect()
			end)

			state.heartbeat = nil
		end

		return
	end

	for object, list in pairs(state.connections) do
		for i = 1, #list do
			pcall(function()
				list[i]:Disconnect()
			end)

			list[i] = nil
		end

		state.connections[object] = nil
	end

	for object in pairs(state.tracked) do
		state.tracked[object] = nil
	end

	for object in pairs(state.locked) do
		state.locked[object] = nil
	end

	for object in pairs(state.descWatching) do
		state.descWatching[object] = nil
	end

	if state.heartbeat then
		pcall(function()
			state.heartbeat:Disconnect()
		end)

		state.heartbeat = nil
	end
end

function protector.destroy()
	protector.cleanup()
	protector.restore()

	pcall(function()
		if isInstance(state.folder) then
			state.folder:Destroy()
		end
	end)

	pcall(function()
		local raw = rawHui()
		if isInstance(state.screen) and not sameInstance(state.screen, raw) then
			state.screen:Destroy()
		end
	end)

	state.folder = nil
	state.screen = nil
end

function protector.support()
	local names = {
		"gethui",
		"gethiddenui",
		"gethiddengui",
		"get_hidden_ui",
		"get_hidden_gui",
		"cloneref",
		"compareinstances",
		"setreadonly",
		"isreadonly",
		"protect_gui",
		"protectgui",
		"protect_ui",
		"protectui",
	}

	local result = {}

	for i = 1, #names do
		result[names[i]] = protector.has(names[i])
	end

	return result
end

function protector.status()
	local raw = rawHui()
	local hui = protector.getHui()
	local parent = protector.getCustomHui()
	local screen = protector.getScreenGui()

	return {
		mode = state.mode,
		raw = raw,
		rawClass = isInstance(raw) and raw.ClassName or nil,
		rawKind = huiKind(raw),
		rawPath = getPath(raw),
		hui = hui,
		huiClass = isInstance(hui) and hui.ClassName or nil,
		huiKind = huiKind(hui),
		huiPath = getPath(hui),
		parent = parent,
		parentClass = isInstance(parent) and parent.ClassName or nil,
		parentPath = getPath(parent),
		screen = screen,
		screenClass = isInstance(screen) and screen.ClassName or nil,
		screenPath = getPath(screen),
		installed = state.installed,
		tracked = trackedCount(),
		support = protector.support(),
	}
end

pcall(function()
	protector.installGetHuiOverride("folder")
end)

if type(cacheHost) == "table" then
	rawset(cacheHost, "__lt_ui_protector", protector)
end

protector.setTableReadonly(protector, true)

return protector