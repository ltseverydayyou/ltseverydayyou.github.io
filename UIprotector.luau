local build = "legacy_na_method_test_v1"
local patch = "old_na_protectui_light_v1"

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

local key = "__lt_ui_protector"
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

local function cached()
	for i = 1, #hosts do
		local ok, v = pcall(rawget, hosts[i], key)
		if ok and type(v) == "table" and rawget(v, "ready") == true then
			return v
		end
	end
	return nil
end

local old = cached()
if type(old) == "table" and rawget(old, "build") == build and rawget(old, "patch") == patch then
	if type(old.installGetHuiOverride) == "function" then
		pcall(old.installGetHuiOverride)
	end
	return old
end

if type(old) == "table" then
	pcall(function()
		if type(old.cleanup) == "function" then
			old.cleanup()
		end
	end)
	pcall(function()
		if type(old.restore) == "function" then
			old.restore()
		end
	end)
end

local protector = {}

local state = {
	customHui = nil,
	screenGui = nil,
	rawHui = nil,
	installed = false,
	cons = setmetatable({}, { __mode = "k" }),
	tracks = setmetatable({}, { __mode = "k" }),
	nameMap = {},
	nameProvider = nil,
	funcs = {},
	native = {},
}

pcall(function()
	state.funcs.gethui = gethui
	state.funcs.gethiddenui = gethiddenui
	state.funcs.gethiddengui = gethiddengui
	state.funcs.get_hidden_ui = get_hidden_ui
	state.funcs.get_hidden_gui = get_hidden_gui
	state.funcs.cloneref = cloneref
	state.funcs.compareinstances = compareinstances
	state.funcs.setreadonly = setreadonly
	state.funcs.isreadonly = isreadonly
	state.funcs.protect_gui = protect_gui
	state.funcs.protectgui = protectgui
	state.funcs.protect_ui = protect_ui
	state.funcs.protectui = protectui
end)

local function isInst(v)
	return typeof(v) == "Instance"
end

local function fn(name)
	local v = state.funcs[name]
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

state.native.gethui = fn("gethui")
state.native.gethiddenui = fn("gethiddenui")
state.native.gethiddengui = fn("gethiddengui")
state.native.get_hidden_ui = fn("get_hidden_ui")
state.native.get_hidden_gui = fn("get_hidden_gui")

function protector.has(name)
	return type(fn(name)) == "function"
end

function protector.getFunction(name)
	return fn(name)
end

local function call(f, ...)
	if type(f) ~= "function" then
		return nil
	end
	local ok, res = pcall(f, ...)
	if ok then
		return res
	end
	return nil
end

local function cref(v)
	local cf = fn("cloneref")
	if type(cf) == "function" and isInst(v) then
		local ok, res = pcall(cf, v)
		if ok and res ~= nil then
			return res
		end
	end
	return v
end

local function svc(name)
	local ok, res = pcall(function()
		local cf = fn("cloneref")
		local s = game:GetService(name)
		if type(cf) == "function" then
			return cf(s)
		end
		return s
	end)
	if ok and isInst(res) then
		return res
	end
	return nil
end

local function isA(v, cls)
	if not isInst(v) then
		return false
	end
	local ok, res = pcall(function()
		return v:IsA(cls)
	end)
	return ok and res == true
end

local function same(a, b)
	if a == b then
		return true
	end
	local cf = fn("compareinstances")
	if type(cf) == "function" and isInst(a) and isInst(b) then
		local ok, res = pcall(cf, a, b)
		if ok then
			return res == true
		end
	end
	return false
end

local function prop(obj, name)
	local ok, res = pcall(function()
		return obj[name]
	end)
	if ok then
		return res
	end
	return nil
end

local function setp(obj, name, val)
	pcall(function()
		obj[name] = val
	end)
end

local function con(obj, c)
	if not c then
		return c
	end
	local list = state.cons[obj]
	if type(list) ~= "table" then
		list = {}
		state.cons[obj] = list
	end
	list[#list + 1] = c
	return c
end

local function alive(obj)
	if not isInst(obj) then
		return false
	end
	local ok, parent = pcall(function()
		return obj.Parent
	end)
	return ok and parent ~= nil
end

local function rname(keyName)
	local provider = state.nameProvider
	if type(provider) == "function" then
		local ok, res = pcall(provider, keyName)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	keyName = tostring(keyName or os.clock())
	if state.nameMap[keyName] then
		return state.nameMap[keyName]
	end
	local hs = svc("HttpService")
	local out
	if isInst(hs) then
		out = call(function()
			return hs:GenerateGUID(false)
		end)
	end
	if type(out) ~= "string" or out == "" then
		local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local t = {}
		for i = 1, 24 do
			local n = math.random(1, #chars)
			t[i] = chars:sub(n, n)
		end
		out = table.concat(t)
	end
	state.nameMap[keyName] = out
	return out
end

function protector.setSessionNameProvider(f)
	state.nameProvider = type(f) == "function" and f or nil
	return state.nameProvider ~= nil
end

function protector.getSessionInstanceName(keyName)
	return rname(keyName)
end

function protector.randomString(keyName)
	return rname(keyName)
end

function protector.nativeProtect(obj)
	if not isInst(obj) then
		return obj
	end
	local names = {
		"protect_gui",
		"protectgui",
		"protect_ui",
		"protectui",
	}
	for i = 1, #names do
		local f = fn(names[i])
		if type(f) == "function" then
			pcall(f, obj)
		end
	end
	return obj
end

function protector.setTableReadonly(tbl, value)
	if type(tbl) ~= "table" then
		return tbl
	end
	local f = fn("setreadonly")
	if type(f) == "function" then
		pcall(f, tbl, value ~= false)
	end
	return tbl
end

local function rawHui()
	local list = {
		state.native.gethui,
		state.native.gethiddenui,
		state.native.gethiddengui,
		state.native.get_hidden_ui,
		state.native.get_hidden_gui,
	}
	for i = 1, #list do
		local res = cref(call(list[i]))
		if isInst(res) and not same(res, state.customHui) and not same(res, state.screenGui) then
			state.rawHui = res
			return res
		end
	end
	return state.rawHui
end

function protector.rawHuiGrabber()
	return rawHui()
end

local function playerGui()
	local ps = svc("Players")
	local lp = isInst(ps) and cref(ps.LocalPlayer) or nil
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

local function coreBase()
	local cg = svc("CoreGui")
	if isInst(cg) then
		local rg = call(function()
			return cg:FindFirstChild("RobloxGui")
		end)
		if isInst(rg) then
			return rg
		end
		return cg
	end
	return playerGui()
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
	if obj.ClassName == "CoreGui" or tostring(obj.Name) == "RobloxGui" then
		return "alias"
	end
	if isA(obj, "BasePlayerGui") or obj.ClassName == "StarterGui" then
		return "root"
	end
	return "other"
end

function protector.getRawHuiKind()
	return kind(rawHui())
end

local function folderParent(parent)
	if isInst(parent) then
		if isA(parent, "ScreenGui") then
			local p = prop(parent, "Parent")
			if isInst(p) then
				return p
			end
		end
		if parent.ClassName == "CoreGui" then
			local rg = call(function()
				return parent:FindFirstChild("RobloxGui")
			end)
			if isInst(rg) then
				return rg
			end
			return parent
		end
		if tostring(parent.Name) == "RobloxGui" or isA(parent, "Folder") or isA(parent, "BasePlayerGui") or parent.ClassName == "StarterGui" then
			return parent
		end
	end
	local raw = rawHui()
	if isInst(raw) then
		if isA(raw, "ScreenGui") then
			local p = prop(raw, "Parent")
			if isInst(p) then
				return p
			end
		elseif raw.ClassName == "CoreGui" then
			local rg = call(function()
				return raw:FindFirstChild("RobloxGui")
			end)
			if isInst(rg) then
				return rg
			end
			return raw
		elseif tostring(raw.Name) == "RobloxGui" or isA(raw, "BasePlayerGui") or raw.ClassName == "StarterGui" then
			return raw
		end
	end
	return coreBase()
end

function protector.getBaseParent()
	return folderParent()
end

local attrRole = "__lt_ui_protector_role"
local attrKey = "__lt_ui_protector_key"
local attrVal = "legacy_na_method_test_v1"

local function mark(obj, role)
	if not isInst(obj) then
		return obj
	end
	pcall(function()
		obj:SetAttribute(attrRole, role)
		obj:SetAttribute(attrKey, attrVal)
	end)
	return obj
end

local function isMarked(obj, role)
	if not isInst(obj) then
		return false
	end
	local ok1, r = pcall(function()
		return obj:GetAttribute(attrRole)
	end)
	local ok2, k = pcall(function()
		return obj:GetAttribute(attrKey)
	end)
	return ok1 and ok2 and r == role and k == attrVal
end

local function findMarked(parent, role, className)
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
		local c = kids[i]
		if isInst(c) and isA(c, className) and isMarked(c, role) then
			return c
		end
	end
	return nil
end

local function screenDefaults(gui)
	if not isInst(gui) or not isA(gui, "ScreenGui") then
		return gui
	end
	setp(gui, "ZIndexBehavior", Enum.ZIndexBehavior.Global)
	setp(gui, "DisplayOrder", 0x7FFFFFFF)
	setp(gui, "ResetOnSpawn", false)
	setp(gui, "IgnoreGuiInset", true)
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
	pcall(function()
		gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	end)
	pcall(function()
		gui.ClipToDeviceSafeArea = false
	end)
	pcall(function()
		gui.OnTopOfCoreBlur = true
	end)
	return gui
end

local function sameVal(propName, a, b)
	if propName == "Parent" then
		return isInst(a) and isInst(b) and same(a, b)
	end
	return a == b
end

function protector.lockInstance(obj, props)
	if not isInst(obj) or type(props) ~= "table" then
		return obj
	end
	local oldTrack = state.tracks[obj]
	if oldTrack and type(oldTrack.props) == "table" then
		for k, v in props do
			oldTrack.props[k] = v
		end
		props = oldTrack.props
	end
	state.tracks[obj] = {
		alive = true,
		props = props,
	}
	for k, v in props do
		if v ~= nil then
			setp(obj, k, v)
		end
	end
	if not oldTrack then
		for k in props do
			local ok, sig = pcall(function()
				return obj:GetPropertyChangedSignal(k)
			end)
			if ok and sig then
				con(obj, sig:Connect(function()
					local tr = state.tracks[obj]
					if not tr or tr.alive ~= true then
						return
					end
					local want = tr.props[k]
					if want ~= nil and not sameVal(k, prop(obj, k), want) then
						setp(obj, k, want)
					end
				end))
			end
		end
		pcall(function()
			con(obj, obj.AncestryChanged:Connect(function()
				local tr = state.tracks[obj]
				if not tr or tr.alive ~= true then
					return
				end
				local want = tr.props.Parent
				if isInst(want) and not sameVal("Parent", prop(obj, "Parent"), want) then
					setp(obj, "Parent", want)
				end
			end))
		end)
		pcall(function()
			con(obj, obj.Destroying:Connect(function()
				local tr = state.tracks[obj]
				if tr then
					tr.alive = false
				end
				state.tracks[obj] = nil
			end))
		end)
		task.spawn(function()
			while state.tracks[obj] and state.tracks[obj].alive == true and alive(obj) do
				task.wait(0.75)
				local tr = state.tracks[obj]
				if not tr or tr.alive ~= true then
					break
				end
				for k, v in tr.props do
					if v ~= nil and not sameVal(k, prop(obj, k), v) then
						setp(obj, k, v)
					end
				end
			end
		end)
	end
	return obj
end

function protector.harden(obj, opts)
	if not isInst(obj) then
		return obj
	end
	opts = type(opts) == "table" and opts or {}
	pcall(function()
		obj.Archivable = false
	end)
	if opts.rename == true then
		pcall(function()
			obj.Name = rname()
		end)
	end
	if opts.deep == true then
		local max = math.max(0, math.floor(tonumber(opts.maxDescendants) or 200))
		local desc = call(function()
			return obj:GetDescendants()
		end)
		if type(desc) == "table" then
			for i = 1, math.min(#desc, max) do
				local d = desc[i]
				if isInst(d) then
					pcall(function()
						d.Archivable = false
					end)
					if opts.rename == true then
						pcall(function()
							d.Name = rname()
						end)
					end
				end
			end
		end
	end
	if opts.watch == true then
		pcall(function()
			con(obj, obj.DescendantAdded:Connect(function(d)
				if isInst(d) then
					pcall(function()
						d.Archivable = false
					end)
					if opts.rename == true then
						pcall(function()
							d.Name = rname()
						end)
					end
				end
			end))
		end)
	end
	return obj
end

function protector.getCustomHui(parent)
	parent = folderParent(parent)
	if not isInst(parent) then
		return nil
	end
	if isInst(state.customHui) and same(prop(state.customHui, "Parent"), parent) then
		mark(state.customHui, "hui")
		return state.customHui
	end
	local found = findMarked(parent, "hui", "Folder")
	if isInst(found) then
		state.customHui = found
	else
		state.customHui = Instance.new("Folder")
		mark(state.customHui, "hui")
	end
	protector.nativeProtect(state.customHui)
	return protector.lockInstance(state.customHui, {
		Name = rname("hui"),
		Parent = parent,
		Archivable = false,
	})
end

function protector.huiGrabber()
	local raw = rawHui()
	local k = kind(raw)
	if k == "folder" then
		return raw
	end
	if k == "screen" or k == "alias" or k == "root" then
		return protector.getCustomHui(raw)
	end
	if isInst(raw) then
		return raw
	end
	return protector.getCustomHui()
end

function protector.getScreenGui(name)
	local parent = protector.huiGrabber()
	if isInst(parent) and isA(parent, "ScreenGui") then
		state.screenGui = parent
		screenDefaults(parent)
		return parent
	end
	if not isInst(parent) then
		return nil
	end
	if isInst(state.screenGui) and same(prop(state.screenGui, "Parent"), parent) then
		mark(state.screenGui, "screen")
		return state.screenGui
	end
	local found = findMarked(parent, "screen", "ScreenGui")
	if isInst(found) then
		state.screenGui = found
	else
		state.screenGui = Instance.new("ScreenGui")
		mark(state.screenGui, "screen")
	end
	protector.nativeProtect(state.screenGui)
	screenDefaults(state.screenGui)
	return protector.lockInstance(state.screenGui, {
		Name = type(name) == "string" and name ~= "" and name or rname("screen"),
		Parent = parent,
		Archivable = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 0x7FFFFFFF,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	})
end

function protector.resolveParent(opts)
	opts = type(opts) == "table" and opts or {}
	local got = call(opts.parentResolver)
	if isInst(got) then
		return cref(got)
	end
	if isInst(opts.parent) then
		return cref(opts.parent)
	end
	return protector.huiGrabber()
end

function protector.parent()
	return protector.huiGrabber()
end

local function uiProps(gui, target, opts)
	local props = {
		Parent = target,
		Archivable = false,
	}
	if not opts.keepName then
		props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or rname()
	end
	if isA(gui, "ScreenGui") then
		props.ZIndexBehavior = Enum.ZIndexBehavior.Global
		props.DisplayOrder = 0x7FFFFFFF
		props.ResetOnSpawn = false
		props.IgnoreGuiInset = true
	end
	return props
end

function protector.protectUI(gui, opts)
	if not isInst(gui) then
		return nil
	end
	opts = type(opts) == "table" and opts or {}
	protector.nativeProtect(gui)
	pcall(function()
		gui.Archivable = false
	end)
	if isA(gui, "ScreenGui") then
		screenDefaults(gui)
		local target = protector.resolveParent(opts)
		if not isInst(target) then
			return nil
		end
		if same(gui, target) then
			return protector.lockInstance(gui, {
				Archivable = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Global,
				DisplayOrder = 0x7FFFFFFF,
				ResetOnSpawn = false,
				IgnoreGuiInset = true,
			})
		end
		protector.lockInstance(gui, uiProps(gui, target, opts))
		if opts.harden == true then
			protector.harden(gui, opts)
		end
		return gui
	end
	local target
	if isInst(opts.parent) and not isA(opts.parent, "Folder") then
		target = cref(opts.parent)
	else
		target = protector.getScreenGui(type(opts.name) == "string" and opts.name or nil)
	end
	if not isInst(target) then
		return nil
	end
	local props = {
		Parent = target,
		Archivable = false,
	}
	if opts.lockName == true then
		props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or rname()
	end
	protector.lockInstance(gui, props)
	if opts.harden == true then
		protector.harden(gui, opts)
	end
	return gui
end

function protector.protectName(obj, propName)
	if not isInst(obj) then
		return nil
	end
	propName = type(propName) == "string" and propName ~= "" and propName or "Name"
	pcall(function()
		obj[propName] = rname()
	end)
	pcall(function()
		obj.Archivable = false
	end)
	return obj
end

function protector.NAProtection(obj, propName)
	return protector.protectName(obj, propName)
end

function protector.NaProtectUI(gui, opts)
	return protector.protectUI(gui, opts)
end

function protector.installGetHuiOverride()
	local function custom()
		return protector.huiGrabber()
	end
	local names = {
		"gethui",
		"gethiddenui",
		"gethiddengui",
		"get_hidden_ui",
		"get_hidden_gui",
	}
	local installed = false
	pcall(function()
		gethui = custom
		gethiddenui = custom
		gethiddengui = custom
		get_hidden_ui = custom
		get_hidden_gui = custom
		installed = true
	end)
	local function apply(env)
		if type(env) ~= "table" then
			return false
		end
		for i = 1, #names do
			rawset(env, names[i], custom)
		end
		return true
	end
	pcall(function()
		if type(getgenv) == "function" then
			installed = apply(getgenv()) or installed
		end
	end)
	pcall(function()
		installed = apply(_G) or installed
	end)
	state.installed = installed == true
	protector.getHuiOverrideInstalled = state.installed
	return state.installed
end

function protector.install()
	return protector.installGetHuiOverride()
end

function protector.restore()
	local native = state.native
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
	pcall(function()
		if type(getgenv) == "function" then
			apply(getgenv())
		end
	end)
	pcall(apply, _G)
	state.installed = false
	protector.getHuiOverrideInstalled = false
end

function protector.cleanup(obj)
	if isInst(obj) then
		local list = state.cons[obj]
		if type(list) == "table" then
			for i = 1, #list do
				pcall(function()
					list[i]:Disconnect()
				end)
				list[i] = nil
			end
		end
		state.cons[obj] = nil
		state.tracks[obj] = nil
		return
	end
	for o, list in state.cons do
		if type(list) == "table" then
			for i = 1, #list do
				pcall(function()
					list[i]:Disconnect()
				end)
				list[i] = nil
			end
		end
		state.cons[o] = nil
	end
	for o in state.tracks do
		state.tracks[o] = nil
	end
end

function protector.destroy()
	protector.cleanup()
	protector.restore()
	pcall(function()
		if isInst(state.screenGui) then
			state.screenGui:Destroy()
		end
	end)
	pcall(function()
		if isInst(state.customHui) then
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
	local out = {}
	for i = 1, #names do
		out[names[i]] = protector.has(names[i])
	end
	return out
end

local function path(obj)
	if not isInst(obj) then
		return nil
	end
	local ok, res = pcall(function()
		return obj:GetFullName()
	end)
	if ok then
		return res
	end
	return obj.ClassName
end

local function count(t)
	local n = 0
	for o in t do
		if isInst(o) then
			n += 1
		end
	end
	return n
end

function protector.status()
	local raw = rawHui()
	local parent = protector.huiGrabber()
	local screen = protector.getScreenGui()
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
		tracked = count(state.tracks),
		support = protector.support(),
	}
end

protector.ready = true
protector.build = build
protector.patch = patch
protector.version = patch

for i = 1, #hosts do
	pcall(rawset, hosts[i], key, protector)
end

protector.installGetHuiOverride()
return protector
