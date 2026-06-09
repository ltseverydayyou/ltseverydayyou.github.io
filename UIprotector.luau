local build = "managed_singleton_v6"
local patch = "non_aggressive_shared_hui_v1"

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

local cacheKey = "__lt_ui_protector"
local hosts = {}

local function addHost(t)
	if type(t) ~= "table" then
		return
	end

	for i = 1, #hosts do
		if hosts[i] == t then
			return
		end
	end

	hosts[#hosts + 1] = t
end

addHost(sharedEnv)
addHost(globalEnv)

pcall(function()
	addHost(_G)
	addHost(rawget(_G, "shared"))
end)

local cacheHost = hosts[1] or globalEnv

local function cachedProtector()
	for i = 1, #hosts do
		local env = hosts[i]
		local ok, ret = pcall(rawget, env, cacheKey)
		if ok and type(ret) == "table" and rawget(ret, "ready") == true then
			return ret
		end
	end

	return nil
end

local cached = cachedProtector()

if type(cached) == "table" and rawget(cached, "build") == build and rawget(cached, "patch") == patch then
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
	installed = false,
	getHuiFn = nil,
	sessionNameProvider = nil,
	sessionNameMap = {},
	funcCache = {},
	localFuncs = {},
	nativeHuiFns = {},
	protected = setmetatable({}, { __mode = "k" }),
	locked = setmetatable({}, { __mode = "k" }),
	nativeDone = setmetatable({}, { __mode = "k" }),
	attrsDone = setmetatable({}, { __mode = "k" }),
	refs = {},
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

local function isInst(v)
	return typeof(v) == "Instance"
end

local function call(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end

	local ok, ret = pcall(fn, ...)
	if ok then
		return ret
	end

	return nil
end

local function capture(name)
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

state.nativeHuiFns.gethui = capture("gethui")
state.nativeHuiFns.gethiddenui = capture("gethiddenui")
state.nativeHuiFns.gethiddengui = capture("gethiddengui")
state.nativeHuiFns.get_hidden_ui = capture("get_hidden_ui")
state.nativeHuiFns.get_hidden_gui = capture("get_hidden_gui")

local function getFunc(name)
	local v = state.localFuncs[name]
	if type(v) == "function" then
		return v
	end

	v = state.funcCache[name]
	if type(v) == "function" then
		return v
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
		local renv = call(gr)
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
	if type(fn) == "function" and isInst(v) then
		local ok, ret = pcall(fn, v)
		if ok and ret ~= nil then
			return ret
		end
	end

	return v
end

local function service(name)
	local ok, ret = pcall(function()
		local fn = getFunc("cloneref")
		if type(fn) == "function" then
			return fn(game:GetService(name))
		end

		return game:GetService(name)
	end)

	if ok and isInst(ret) then
		return ret
	end

	return nil
end

local function isA(v, class)
	if not isInst(v) then
		return false
	end

	local ok, ret = pcall(function()
		return v:IsA(class)
	end)

	return ok and ret == true
end

local function sameInst(a, b)
	if a == b then
		return true
	end

	local fn = getFunc("compareinstances")
	if type(fn) == "function" and isInst(a) and isInst(b) then
		local ok, ret = pcall(fn, a, b)
		if ok then
			return ret == true
		end
	end

	return false
end

local function getProp(obj, prop)
	local ok, ret = pcall(function()
		return obj[prop]
	end)

	if ok then
		return ret
	end

	return nil
end

local function setProp(obj, prop, val)
	pcall(function()
		obj[prop] = val
	end)
end

local function enum(a, b)
	local ok, ret = pcall(function()
		return Enum[a][b]
	end)

	if ok then
		return ret
	end

	return nil
end

local function path(obj)
	if not isInst(obj) then
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

local function guid()
	local hs = service("HttpService")
	if isInst(hs) then
		local ok, ret = pcall(function()
			return hs:GenerateGUID(false)
		end)

		if ok and type(ret) == "string" and ret ~= "" then
			return ret
		end
	end

	return tostring(math.floor(os.clock() * 1000000)) .. tostring(math.random(1000, 9999))
end

local function setAttr(obj, key, val)
	if not isInst(obj) then
		return
	end

	if state.attrsDone[obj] ~= true then
		state.attrsDone[obj] = true
	end

	pcall(function()
		obj:SetAttribute(key, val)
	end)
end

local rootKey = "lt-ui-protector-managed-root-v6"
local roleAttr = "__lt_ui_protector_role"
local keyAttr = "__lt_ui_protector_key"
local roleHui = "hui"
local roleScreen = "screen"

local function mark(obj, role)
	setAttr(obj, roleAttr, role)
	setAttr(obj, keyAttr, rootKey)
	return obj
end

local function marked(obj, role)
	if not isInst(obj) then
		return false
	end

	local okRole, gotRole = pcall(function()
		return obj:GetAttribute(roleAttr)
	end)

	local okKey, gotKey = pcall(function()
		return obj:GetAttribute(keyAttr)
	end)

	return okRole and okKey and gotRole == role and gotKey == rootKey
end

local function findMarked(parent, role, class)
	if not isInst(parent) then
		return nil
	end

	local kids = call(function()
		return parent:GetChildren()
	end)

	if type(kids) ~= "table" then
		return nil
	end

	for i = 1, #kids do
		local child = kids[i]
		if isInst(child) and isA(child, class) and marked(child, role) then
			return child
		end
	end

	return nil
end

function protector.setSessionNameProvider(fn)
	state.sessionNameProvider = type(fn) == "function" and fn or nil
	return state.sessionNameProvider ~= nil
end

function protector.getSessionInstanceName(key)
	local fn = state.sessionNameProvider
	if type(fn) == "function" then
		local ok, ret = pcall(fn, key)
		if ok and type(ret) == "string" and ret ~= "" then
			return ret
		end
	end

	key = tostring(key or "default")
	local old = state.sessionNameMap[key]
	if type(old) == "string" and old ~= "" then
		return old
	end

	local ret = "LTUI_" .. guid()
	state.sessionNameMap[key] = ret
	return ret
end

function protector.randomString(key)
	return protector.getSessionInstanceName(key or guid())
end

function protector.nativeProtect(obj)
	if not isInst(obj) then
		return obj
	end

	if state.nativeDone[obj] then
		return obj
	end

	state.nativeDone[obj] = true

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
		local ret = cloneRef(call(fns[i]))
		if isInst(ret) and not sameInst(ret, state.customHui) and not sameInst(ret, state.screenGui) then
			state.rawHui = ret
			return ret
		end
	end

	return state.rawHui
end

function protector.rawHuiGrabber()
	return rawHui()
end

local function playerGui()
	local ps = service("Players")
	local lp = isInst(ps) and cloneRef(ps.LocalPlayer) or nil
	if isInst(lp) then
		local pg = call(function()
			return lp:FindFirstChildWhichIsA("PlayerGui")
		end)

		if isInst(pg) then
			return pg
		end
	end

	return nil
end

local function robloxGui(parent)
	if not isInst(parent) then
		return nil
	end

	local rg = call(function()
		return parent:FindFirstChild("RobloxGui")
	end)

	if isInst(rg) then
		return rg
	end

	return nil
end

local function kind(obj)
	if not isInst(obj) then
		return nil
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

	local cn = obj.ClassName
	if cn == "CoreGui" or cn == "PlayerGui" or cn == "StarterGui" then
		return "root"
	end

	return "other"
end

function protector.getRawHuiKind()
	return kind(rawHui())
end

function protector.getBaseParent()
	local cg = service("CoreGui")
	if isInst(cg) then
		return robloxGui(cg) or cg
	end

	return playerGui()
end

local function folderParent(parent)
	if isInst(parent) then
		local cn = parent.ClassName
		if cn == "CoreGui" then
			return robloxGui(parent) or parent
		end

		if cn == "RobloxGui" or cn == "PlayerGui" or cn == "StarterGui" then
			return parent
		end

		if isA(parent, "BasePlayerGui") then
			return parent
		end
	end

	return protector.getBaseParent()
end

local function screenDefaults(gui)
	if not isInst(gui) then
		return gui
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

	local z = enum("ZIndexBehavior", "Global")
	if z then
		pcall(function()
			gui.ZIndexBehavior = z
		end)
	end

	local s = enum("ScreenInsets", "None")
	if s then
		pcall(function()
			gui.ScreenInsets = s
		end)
	end

	local a = enum("SafeAreaCompatibility", "None")
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

function protector.lockInstance(obj, props)
	if not isInst(obj) or type(props) ~= "table" then
		return obj
	end

	local old = state.locked[obj]
	if type(old) ~= "table" then
		old = {}
		state.locked[obj] = old
	end

	for prop, val in props do
		old[prop] = val
		setProp(obj, prop, val)
	end

	state.protected[obj] = true
	return obj
end

local function renameDesc(obj, max)
	local desc = call(function()
		return obj:GetDescendants()
	end)

	if type(desc) ~= "table" then
		return 0
	end

	max = tonumber(max) or 120
	local done = 0

	for i = 1, #desc do
		local d = desc[i]
		if isInst(d) then
			pcall(function()
				d.Name = protector.randomString(d.ClassName)
			end)
			done += 1
			if done >= max then
				break
			end
		end
	end

	return done
end

function protector.harden(obj, opts)
	if not isInst(obj) then
		return obj
	end

	opts = type(opts) == "table" and opts or {}

	if opts.rename == true then
		pcall(function()
			obj.Name = protector.randomString(obj.ClassName)
		end)
	end

	if opts.deep == true and opts.rename == true then
		renameDesc(obj, opts.maxDescendants)
	end

	state.protected[obj] = true
	return obj
end

function protector.protectInstance(obj, opts)
	if not isInst(obj) then
		return nil
	end

	opts = type(opts) == "table" and opts or {}
	protector.nativeProtect(obj)

	local props = {}

	if opts.renameRoot == true then
		local name = type(opts.name) == "string" and opts.name ~= "" and opts.name or protector.randomString(opts.nameKey or obj.ClassName)
		props.Name = name
	end

	if isInst(opts.parent) then
		props.Parent = opts.parent
	elseif opts.enforceParent == true then
		props.Parent = nil
	end

	if next(props) ~= nil then
		protector.lockInstance(obj, props)
	else
		state.protected[obj] = true
	end

	if opts.renameDescendants == true then
		renameDesc(obj, opts.maxDescendants)
	end

	return obj
end

function protector.protectCachedInternal(obj, opts)
	opts = type(opts) == "table" and opts or {}
	opts.renameRoot = opts.renameRoot ~= false
	opts.renameDescendants = opts.renameDescendants == true
	opts.enforceParent = opts.enforceParent == true
	return protector.protectInstance(obj, opts)
end

function protector.getCustomHui(parent)
	parent = folderParent(parent)
	if not isInst(parent) then
		return nil
	end

	if isInst(state.customHui) and sameInst(state.customHui.Parent, parent) then
		mark(state.customHui, roleHui)
		return state.customHui
	end

	local old = findMarked(parent, roleHui, "Folder")
	if isInst(old) then
		state.customHui = old
		mark(old, roleHui)
		protector.nativeProtect(old)
		return protector.lockInstance(old, {
			Parent = parent,
		})
	end

	local folder = Instance.new("Folder")
	folder.Name = protector.randomString("hui")
	mark(folder, roleHui)
	folder.Parent = parent
	state.customHui = folder
	protector.nativeProtect(folder)
	return protector.lockInstance(folder, {
		Parent = parent,
	})
end

function protector.huiGrabber()
	local folder = protector.getCustomHui()
	if isInst(folder) then
		return folder
	end

	return rawHui()
end

function protector.getScreenGui(name)
	local parent = protector.huiGrabber()
	if not isInst(parent) then
		return nil
	end

	if isA(parent, "ScreenGui") then
		state.screenGui = parent
		return screenDefaults(parent)
	end

	if isInst(state.screenGui) and sameInst(state.screenGui.Parent, parent) then
		mark(state.screenGui, roleScreen)
		return screenDefaults(state.screenGui)
	end

	local old = findMarked(parent, roleScreen, "ScreenGui")
	if isInst(old) then
		state.screenGui = old
		mark(old, roleScreen)
		screenDefaults(old)
		protector.nativeProtect(old)
		return protector.lockInstance(old, {
			Parent = parent,
		})
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = type(name) == "string" and name ~= "" and name or protector.randomString("screen")
	mark(gui, roleScreen)
	screenDefaults(gui)
	gui.Parent = parent
	state.screenGui = gui
	protector.nativeProtect(gui)
	return protector.lockInstance(gui, {
		Parent = parent,
	})
end

function protector.resolveParent(opts)
	opts = type(opts) == "table" and opts or {}

	local fromResolver = call(opts.parentResolver)
	if isInst(fromResolver) then
		return cloneRef(fromResolver)
	end

	if isInst(opts.parent) then
		return cloneRef(opts.parent)
	end

	return protector.huiGrabber()
end

function protector.parent()
	return protector.huiGrabber()
end

function protector.protectUI(gui, opts)
	if not isInst(gui) then
		return nil
	end

	opts = type(opts) == "table" and opts or {}
	protector.nativeProtect(gui)

	if isA(gui, "ScreenGui") then
		screenDefaults(gui)

		local target = protector.resolveParent(opts)
		if not isInst(target) then
			return nil
		end

		if isA(target, "ScreenGui") and not sameInst(gui, target) then
			target = protector.huiGrabber()
		end

		if sameInst(gui, target) then
			state.protected[gui] = true
			return gui
		end

		local props = {
			Parent = target,
		}

		if not opts.keepName then
			props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or protector.randomString(gui.ClassName)
		end

		protector.lockInstance(gui, props)

		if opts.harden == true then
			protector.harden(gui, {
				deep = opts.deep == true,
				rename = opts.rename == true,
				maxDescendants = opts.maxDescendants,
			})
		end

		return gui
	end

	local target = protector.getScreenGui(opts.screenName)
	if not isInst(target) then
		return nil
	end

	local props = {
		Parent = target,
	}

	if opts.lockName == true then
		props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or protector.randomString(gui.ClassName)
	end

	protector.lockInstance(gui, props)

	if opts.harden == true then
		protector.harden(gui, {
			deep = opts.deep == true,
			rename = opts.rename == true,
			maxDescendants = opts.maxDescendants,
		})
	end

	return gui
end

function protector.protectName(obj, prop)
	if not isInst(obj) then
		return nil
	end

	pcall(function()
		obj[prop or "Name"] = protector.randomString(prop or obj.ClassName)
	end)

	return obj
end

local function aliases()
	return {
		"gethui",
		"gethiddenui",
		"gethiddengui",
		"get_hidden_ui",
		"get_hidden_gui",
	}
end

local function applyAliases(env, fn)
	if type(env) ~= "table" then
		return false
	end

	local names = aliases()
	for i = 1, #names do
		rawset(env, names[i], fn)
	end

	return true
end

function protector.installGetHuiOverride()
	if type(state.getHuiFn) ~= "function" then
		state.getHuiFn = function()
			return protector.huiGrabber()
		end
	end

	local fn = state.getHuiFn
	local installed = false

	pcall(function()
		gethui = fn
		gethiddenui = fn
		gethiddengui = fn
		get_hidden_ui = fn
		get_hidden_gui = fn
		installed = true
	end)

	pcall(function()
		if type(getgenv) == "function" then
			installed = applyAliases(getgenv(), fn) or installed
		end
	end)

	pcall(function()
		installed = applyAliases(_G, fn) or installed
	end)

	pcall(function()
		if type(shared) == "table" then
			applyAliases(shared, fn)
		end
	end)

	state.installed = installed
	protector.getHuiOverrideInstalled = installed
	return installed
end

function protector.install()
	return protector.installGetHuiOverride()
end

function protector.restore()
	local native = state.nativeHuiFns
	local map = {
		gethui = native.gethui,
		gethiddenui = native.gethiddenui,
		gethiddengui = native.gethiddengui,
		get_hidden_ui = native.get_hidden_ui,
		get_hidden_gui = native.get_hidden_gui,
	}

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

		for name, fn in map do
			rawset(env, name, fn)
		end
	end

	pcall(function()
		if type(getgenv) == "function" then
			apply(getgenv())
		end
	end)

	pcall(apply, _G)

	pcall(function()
		if type(shared) == "table" then
			apply(shared)
		end
	end)

	state.installed = false
	protector.getHuiOverrideInstalled = false
end

function protector.acquire(id)
	id = tostring(id or "default")
	state.refs[id] = (tonumber(state.refs[id]) or 0) + 1
	return protector
end

function protector.release(id)
	id = tostring(id or "default")
	local n = (tonumber(state.refs[id]) or 1) - 1
	if n <= 0 then
		state.refs[id] = nil
	else
		state.refs[id] = n
	end
	return n
end

function protector.cleanup(obj)
	if isInst(obj) then
		state.protected[obj] = nil
		state.locked[obj] = nil
		state.nativeDone[obj] = nil
		state.attrsDone[obj] = nil
		return
	end

	state.protected = setmetatable({}, { __mode = "k" })
	state.locked = setmetatable({}, { __mode = "k" })
	state.nativeDone = setmetatable({}, { __mode = "k" })
	state.attrsDone = setmetatable({}, { __mode = "k" })
end

function protector.destroy()
	protector.cleanup()
	protector.restore()

	pcall(function()
		if isInst(state.screenGui) and marked(state.screenGui, roleScreen) then
			state.screenGui:Destroy()
		end
	end)

	pcall(function()
		if isInst(state.customHui) and marked(state.customHui, roleHui) then
			state.customHui:Destroy()
		end
	end)

	state.screenGui = nil
	state.customHui = nil
end

local function count(tbl)
	local n = 0
	for obj in tbl do
		if isInst(obj) then
			n += 1
		end
	end
	return n
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

	local ret = {}
	for i = 1, #names do
		ret[names[i]] = protector.has(names[i])
	end

	return ret
end

function protector.status()
	local raw = rawHui()
	local parent = protector.huiGrabber()
	local screen = protector.getScreenGui()
	local refTotal = 0

	for _, n in state.refs do
		refTotal += tonumber(n) or 0
	end

	return {
		build = build,
		patch = patch,
		raw = raw,
		rawClass = isInst(raw) and raw.ClassName or nil,
		rawKind = kind(raw),
		rawPath = path(raw),
		parent = parent,
		parentClass = isInst(parent) and parent.ClassName or nil,
		parentKind = kind(parent),
		parentPath = path(parent),
		screen = screen,
		screenClass = isInst(screen) and screen.ClassName or nil,
		screenPath = path(screen),
		installed = state.installed,
		tracked = count(state.protected),
		locked = count(state.locked),
		refs = refTotal,
		support = protector.support(),
	}
end

protector.ready = true
protector.build = build
protector.patch = patch
protector.__state = state
protector.__cacheKey = cacheKey

pcall(function()
	protector.installGetHuiOverride()
end)

for i = 1, #hosts do
	pcall(rawset, hosts[i], cacheKey, protector)
end

return protector
