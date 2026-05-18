local build = "fallback_order"

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

if type(cached) == "table" and rawget(cached, "ready") == true and rawget(cached, "build") == build then
	if type(cached.installGetHuiOverride) == "function" then
		pcall(cached.installGetHuiOverride)
	end
	return cached
end

if type(cached) == "table" then
	pcall(function()
		if type(cached.cleanup) == "function" then
			cached.cleanup()
		end
	end)

	pcall(function()
		if type(cached.restore) == "function" then
			cached.restore()
		end
	end)
end

local protector = {}

local state = {
	customHui = nil,
	screenGui = nil,
	rawHui = nil,
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

local function isInstance(v)
	return typeof(v) == "Instance"
end

local function tryCall(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end

	local ok, ret = pcall(fn, ...)
	if ok then
		return ret
	end

	return nil
end

local function captureFunc(name)
	local v = state.localFuncs[name]

	if type(v) == "function" then
		return v
	end

	if type(globalEnv) == "table" then
		v = rawget(globalEnv, name)
		if type(v) == "function" then
			return v
		end
	end

	pcall(function()
		if type(_G) == "table" then
			v = rawget(_G, name)
		end
	end)

	if type(v) == "function" then
		return v
	end

	return nil
end

state.nativeHuiFns.gethui = captureFunc("gethui")
state.nativeHuiFns.gethiddenui = captureFunc("gethiddenui")
state.nativeHuiFns.gethiddengui = captureFunc("gethiddengui")
state.nativeHuiFns.get_hidden_ui = captureFunc("get_hidden_ui")
state.nativeHuiFns.get_hidden_gui = captureFunc("get_hidden_gui")

local function getFunc(name)
	local v = state.localFuncs[name]

	if type(v) == "function" then
		return v
	end

	if type(state.funcCache[name]) == "function" then
		return state.funcCache[name]
	end

	if type(globalEnv) == "table" then
		v = rawget(globalEnv, name)
		if type(v) == "function" then
			state.funcCache[name] = v
			return v
		end
	end

	pcall(function()
		if type(_G) == "table" then
			v = rawget(_G, name)
		end
	end)

	if type(v) == "function" then
		state.funcCache[name] = v
		return v
	end

	local gr = state.localFuncs.getrenv

	if type(gr) ~= "function" and type(globalEnv) == "table" then
		gr = rawget(globalEnv, "getrenv")
	end

	if type(gr) == "function" then
		local renv = tryCall(gr)
		if type(renv) == "table" then
			v = rawget(renv, name)
			if type(v) == "function" then
				state.funcCache[name] = v
				return v
			end
		end
	end

	return nil
end

function protector.has(name)
	return type(getFunc(name)) == "function"
end

function protector.getFunction(name)
	return getFunc(name)
end

local function cloneRef(v)
	local fn = getFunc("cloneref")

	if type(fn) == "function" and isInstance(v) then
		local ok, ret = pcall(fn, v)
		if ok and ret ~= nil then
			return ret
		end
	end

	return v
end

local function getService(name)
	local ok, ret = pcall(function()
		local fn = getFunc("cloneref")
		if type(fn) == "function" then
			return fn(game:GetService(name))
		end

		return game:GetService(name)
	end)

	if ok and isInstance(ret) then
		return ret
	end

	return nil
end

local function isA(v, class)
	if not isInstance(v) then
		return false
	end

	local ok, ret = pcall(function()
		return v:IsA(class)
	end)

	return ok and ret == true
end

local function sameInstance(a, b)
	if a == b then
		return true
	end

	local fn = getFunc("compareinstances")

	if type(fn) == "function" and isInstance(a) and isInstance(b) then
		local ok, ret = pcall(fn, a, b)
		if ok then
			return ret == true
		end
	end

	return false
end

local function getProperty(obj, prop)
	local ok, ret = pcall(function()
		return obj[prop]
	end)

	if ok then
		return ret
	end

	return nil
end

local function setProperty(obj, prop, val)
	pcall(function()
		obj[prop] = val
	end)
end

local function addConnection(obj, con)
	if not con then
		return
	end

	local list = state.connections[obj]
	if not list then
		list = {}
		state.connections[obj] = list
	end

	list[#list + 1] = con
end

local function getEnum(a, b)
	local ok, ret = pcall(function()
		return Enum[a][b]
	end)

	if ok then
		return ret
	end

	return nil
end

local function getPath(obj)
	if not isInstance(obj) then
		return nil
	end

	local ok, ret = pcall(function()
		return obj:GetFullName()
	end)

	if ok then
		return ret
	end

	return obj.ClassName
end

local function trackedCount()
	local n = 0

	for obj in pairs(state.tracked) do
		if isInstance(obj) then
			n += 1
		end
	end

	return n
end

function protector.randomString()
	local hs = getService("HttpService")

	if isInstance(hs) and hs.GenerateGUID then
		local ok, ret = pcall(function()
			return hs:GenerateGUID(false)
		end)

		if ok and type(ret) == "string" and ret ~= "" then
			local pre = math.random(1, 3) == 1 and "\0" or ""
			local suf = math.random(1, 3) == 1 and "​" or ""
			return pre .. ret .. suf
		end
	end

	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local len = math.random(18, 32)
	local out = {}

	for i = 1, len do
		local n = math.random(1, #chars)
		out[i] = chars:sub(n, n)
	end

	if math.random(1, 3) == 1 then
		out[#out + 1] = "\0"
	end

	if math.random(1, 3) == 1 then
		out[#out + 1] = "​"
	end

	return table.concat(out)
end

function protector.nativeProtect(obj)
	if not isInstance(obj) then
		return obj
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
			pcall(fn, obj)
		end
	end

	return obj
end

function protector.setTableReadonly(tbl, value)
	if type(tbl) ~= "table" then
		return tbl
	end

	local fn = getFunc("setreadonly")

	if type(fn) == "function" then
		pcall(fn, tbl, value ~= false)
	end

	return tbl
end

local function rawHui()
	local fns = {
		state.nativeHuiFns.gethui,
		state.nativeHuiFns.gethiddenui,
		state.nativeHuiFns.gethiddengui,
		state.nativeHuiFns.get_hidden_ui,
		state.nativeHuiFns.get_hidden_gui,
	}

	for i = 1, #fns do
		local ret = cloneRef(tryCall(fns[i]))
		if isInstance(ret) and not sameInstance(ret, state.customHui) and not sameInstance(ret, state.screenGui) then
			state.rawHui = ret
			return ret
		end
	end

	return state.rawHui
end

function protector.rawHuiGrabber()
	return rawHui()
end

local function getPlayerGuiContainer()
	local players = getService("Players")
	local lp = isInstance(players) and cloneRef(players.LocalPlayer) or nil

	if isInstance(lp) then
		local pg = tryCall(function()
			return lp:FindFirstChildWhichIsA("PlayerGui")
		end)

		if isInstance(pg) then
			return pg
		end
	end

	return nil
end

local function isRobloxGuiName(obj)
	return isInstance(obj) and tostring(obj.Name or "") == "RobloxGui"
end

local function isAliasRoot(obj, coreGui)
	if not isInstance(obj) then
		return false
	end

	if isRobloxGuiName(obj) then
		return true
	end

	coreGui = isInstance(coreGui) and coreGui or getService("CoreGui")

	if isInstance(coreGui) and sameInstance(obj, coreGui) then
		return true
	end

	local class = obj.ClassName

	if class == "CoreGui" or class == "PlayerGui" or class == "StarterGui" then
		return true
	end

	return false
end

local function huiKind(obj)
	if not isInstance(obj) then
		return nil
	end

	local coreGui = getService("CoreGui")

	if isAliasRoot(obj, coreGui) then
		return "alias"
	end

	if isA(obj, "ScreenGui") then
		return "screen"
	end

	if isA(obj, "Folder") then
		return "folder"
	end

	if isA(obj, "BasePlayerGui") then
		return "root"
	end

	return "other"
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

	return getPlayerGuiContainer()
end

local function getFolderParent(parent)
	if isInstance(parent) then
		if isRobloxGuiName(parent) then
			return parent
		end

		if parent.ClassName == "CoreGui" then
			local robloxGui = tryCall(function()
				return parent:FindFirstChild("RobloxGui")
			end)

			if isInstance(robloxGui) then
				return robloxGui
			end

			return parent
		end

		if parent.ClassName == "PlayerGui" or parent.ClassName == "StarterGui" then
			return parent
		end

		if isA(parent, "BasePlayerGui") then
			return parent
		end
	end

	return protector.getBaseParent()
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

		for obj, cfg in pairs(state.tracked) do
			if not isInstance(obj) or cfg.dead then
				state.tracked[obj] = nil
				state.locked[obj] = nil
				state.descWatching[obj] = nil
			else
				active = true

				for prop, val in pairs(cfg.properties) do
					local cur = getProperty(obj, prop)

					if prop == "Parent" then
						if isInstance(val) and not sameInstance(cur, val) then
							setProperty(obj, prop, val)
						end
					elseif cur ~= val then
						setProperty(obj, prop, val)
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

function protector.lockInstance(obj, props)
	if not isInstance(obj) or type(props) ~= "table" then
		return obj
	end

	for prop, val in pairs(props) do
		setProperty(obj, prop, val)
	end

	state.tracked[obj] = {
		properties = props,
		dead = false,
	}

	if not state.locked[obj] then
		state.locked[obj] = true

		for prop in pairs(props) do
			local ok, sig = pcall(function()
				return obj:GetPropertyChangedSignal(prop)
			end)

			if ok and sig then
				addConnection(obj, sig:Connect(function()
					local cfg = state.tracked[obj]
					if not cfg or cfg.dead then
						return
					end

					local val = cfg.properties[prop]
					local cur = getProperty(obj, prop)

					if prop == "Parent" then
						if isInstance(val) and not sameInstance(cur, val) then
							setProperty(obj, prop, val)
						end
					elseif cur ~= val then
						setProperty(obj, prop, val)
					end
				end))
			end
		end

		pcall(function()
			addConnection(obj, obj.AncestryChanged:Connect(function()
				local cfg = state.tracked[obj]
				if not cfg or cfg.dead then
					return
				end

				local par = cfg.properties.Parent
				if isInstance(par) and not sameInstance(obj.Parent, par) then
					setProperty(obj, "Parent", par)
				end
			end))
		end)

		pcall(function()
			addConnection(obj, obj.Destroying:Connect(function()
				local cfg = state.tracked[obj]
				if cfg then
					cfg.dead = true
				end

				state.tracked[obj] = nil
				state.locked[obj] = nil
				state.descWatching[obj] = nil
			end))
		end)
	end

	startWatchdog()
	return obj
end

function protector.harden(obj, opts)
	if not isInstance(obj) then
		return obj
	end

	opts = type(opts) == "table" and opts or {}

	pcall(function()
		obj.Archivable = false
	end)

	if opts.rename then
		pcall(function()
			obj.Name = protector.randomString()
		end)
	end

	if opts.deep then
		local desc = tryCall(function()
			return obj:GetDescendants()
		end)

		if type(desc) == "table" then
			for i = 1, #desc do
				local d = desc[i]
				if isInstance(d) then
					pcall(function()
						d.Archivable = false
					end)

					if opts.rename then
						pcall(function()
							d.Name = protector.randomString()
						end)
					end
				end
			end
		end
	end

	if opts.watch and not state.descWatching[obj] then
		state.descWatching[obj] = true

		pcall(function()
			addConnection(obj, obj.DescendantAdded:Connect(function(d)
				if not isInstance(d) then
					return
				end

				pcall(function()
					d.Archivable = false
				end)

				if opts.rename then
					pcall(function()
						d.Name = protector.randomString()
					end)
				end
			end))
		end)
	end

	return obj
end

local function applyScreenDefaults(gui)
	if not isInstance(gui) then
		return nil
	end

	pcall(function()
		gui.ResetOnSpawn = false
	end)

	pcall(function()
		gui.IgnoreGuiInset = true
	end)

	pcall(function()
		gui.DisplayOrder = 2147483647
	end)

	local z = getEnum("ZIndexBehavior", "Global")
	if z then
		pcall(function()
			gui.ZIndexBehavior = z
		end)
	end

	local s = getEnum("ScreenInsets", "None")
	if s then
		pcall(function()
			gui.ScreenInsets = s
		end)
	end

	local a = getEnum("SafeAreaCompatibility", "None")
	if a then
		pcall(function()
			gui.SafeAreaCompatibility = a
		end)
	end

	pcall(function()
		gui.ClipToDeviceSafeArea = false
	end)

	pcall(function()
		gui.OnTopOfCoreBlur = true
	end)

	return gui
end

local function protectFolder(folder, parent, name)
	protector.nativeProtect(folder)

	return protector.lockInstance(folder, {
		Name = type(name) == "string" and name ~= "" and name or protector.randomString(),
		Parent = parent,
		Archivable = false,
	})
end

local function protectScreen(gui, parent, name)
	applyScreenDefaults(gui)
	protector.nativeProtect(gui)

	return protector.lockInstance(gui, {
		Name = type(name) == "string" and name ~= "" and name or protector.randomString(),
		Parent = parent,
		Archivable = false,
	})
end

local function protectNativeScreen(gui)
	applyScreenDefaults(gui)
	protector.nativeProtect(gui)

	local par = getProperty(gui, "Parent")

	if isInstance(par) then
		protector.lockInstance(gui, {
			Parent = par,
			Archivable = false,
		})
	else
		pcall(function()
			gui.Archivable = false
		end)
	end

	return gui
end

function protector.getCustomHui(parent)
	parent = getFolderParent(parent)

	if not isInstance(parent) then
		return nil
	end

	if isInstance(state.customHui) and sameInstance(state.customHui.Parent, parent) then
		return state.customHui
	end

	local folder = Instance.new("Folder")
	state.customHui = folder

	return protectFolder(folder, parent)
end

function protector.huiGrabber()
	local hidden = protector.rawHuiGrabber()
	local kind = huiKind(hidden)

	if isInstance(hidden) then
		if kind == "screen" then
			state.screenGui = hidden
			return protectNativeScreen(hidden)
		end

		if kind == "folder" then
			return hidden
		end

		if kind == "root" then
			return hidden
		end

		if kind == "alias" then
			return protector.getCustomHui(hidden)
		end

		return hidden
	end

	return protector.getCustomHui()
end

function protector.getScreenGui(name)
	local hidden = protector.huiGrabber()

	if isInstance(hidden) and isA(hidden, "ScreenGui") then
		state.screenGui = hidden
		return hidden
	end

	if not isInstance(hidden) then
		return nil
	end

	if isInstance(state.screenGui) and sameInstance(state.screenGui.Parent, hidden) then
		return state.screenGui
	end

	local gui = Instance.new("ScreenGui")
	state.screenGui = gui

	return protectScreen(gui, hidden, name)
end

function protector.resolveParent(opts)
	opts = type(opts) == "table" and opts or {}

	local fromResolver = tryCall(opts.parentResolver)
	if isInstance(fromResolver) then
		return fromResolver
	end

	if isInstance(opts.parent) then
		return cloneRef(opts.parent)
	end

	local hidden = protector.huiGrabber()
	if isInstance(hidden) then
		return hidden
	end

	return protector.getCustomHui()
end

function protector.parent()
	return protector.huiGrabber()
end

function protector.protectUI(gui, opts)
	if not isInstance(gui) then
		return nil
	end

	opts = type(opts) == "table" and opts or {}

	protector.nativeProtect(gui)

	if isA(gui, "ScreenGui") then
		applyScreenDefaults(gui)

		local target = protector.resolveParent(opts)
		if not isInstance(target) then
			return nil
		end

		if sameInstance(gui, target) then
			return protectNativeScreen(gui)
		end

		local props = {
			Parent = target,
			Archivable = false,
		}

		if not opts.keepName then
			props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or protector.randomString()
		end

		protector.lockInstance(gui, props)

		if opts.harden == true then
			protector.harden(gui, {
				deep = opts.deep == true,
				watch = opts.watch == true,
				rename = opts.rename == true,
			})
		end

		return gui
	end

	local target = protector.getScreenGui()
	if not isInstance(target) then
		return nil
	end

	local props = {
		Parent = target,
		Archivable = false,
	}

	if opts.lockName == true then
		props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or protector.randomString()
	end

	protector.lockInstance(gui, props)

	if opts.harden == true then
		protector.harden(gui, {
			deep = opts.deep == true,
			watch = opts.watch == true,
			rename = opts.rename == true,
		})
	end

	return gui
end

function protector.protectName(obj, prop)
	if not isInstance(obj) then
		return nil
	end

	pcall(function()
		obj[prop or "Name"] = protector.randomString()
	end)

	pcall(function()
		obj.Archivable = false
	end)

	return obj
end

function protector.installGetHuiOverride()
	local function customGetHui()
		return protector.huiGrabber()
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

	local function apply(env)
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

	local okGlobal = pcall(apply, globalEnv)
	local okG = pcall(apply, _G)

	state.installed = installed or okGlobal or okG

	pcall(function()
		protector.getHuiOverrideInstalled = state.installed
	end)

	return state.installed
end

function protector.install()
	return protector.installGetHuiOverride()
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

	local function apply(env)
		if type(env) ~= "table" then
			return
		end

		rawset(env, "gethui", native.gethui)
		rawset(env, "gethiddenui", native.gethiddenui)
		rawset(env, "gethiddengui", native.gethiddengui)
		rawset(env, "get_hidden_ui", native.get_hidden_ui)
		rawset(env, "get_hidden_gui", native.get_hidden_gui)
	end

	pcall(apply, globalEnv)
	pcall(apply, _G)

	state.installed = false

	pcall(function()
		protector.getHuiOverrideInstalled = false
	end)
end

function protector.cleanup(obj)
	if isInstance(obj) then
		local list = state.connections[obj]

		if list then
			for i = 1, #list do
				pcall(function()
					list[i]:Disconnect()
				end)

				list[i] = nil
			end
		end

		state.connections[obj] = nil
		state.tracked[obj] = nil
		state.locked[obj] = nil
		state.descWatching[obj] = nil

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
		if isInstance(state.screenGui) then
			local raw = rawHui()
			if not sameInstance(state.screenGui, raw) then
				state.screenGui:Destroy()
			end
		end
	end)

	pcall(function()
		if isInstance(state.customHui) then
			state.customHui:Destroy()
		end
	end)

	state.screenGui = nil
	state.customHui = nil
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
	local parent = protector.huiGrabber()
	local screen = protector.getScreenGui()

	return {
		build = build,
		raw = raw,
		rawClass = isInstance(raw) and raw.ClassName or nil,
		rawKind = huiKind(raw),
		rawPath = getPath(raw),
		parent = parent,
		parentClass = isInstance(parent) and parent.ClassName or nil,
		parentKind = huiKind(parent),
		parentPath = getPath(parent),
		screen = screen,
		screenClass = isInstance(screen) and screen.ClassName or nil,
		screenPath = getPath(screen),
		installed = state.installed,
		tracked = trackedCount(),
		support = protector.support(),
	}
end

protector.ready = true
protector.build = build

pcall(function()
	protector.installGetHuiOverride()
end)

if type(cacheHost) == "table" then
	rawset(cacheHost, "__lt_ui_protector", protector)
end

protector.setTableReadonly(protector, true)

return protector