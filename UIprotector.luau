local build = "old_na_method_v1"
local patch = "custom_gethui_folder_v1"

local okEnv, env = pcall(function()
	if type(getgenv) == "function" then
		return getgenv()
	end
end)

if not okEnv or type(env) ~= "table" then
	env = type(_G) == "table" and _G or {}
end

local sh
pcall(function()
	sh = shared
end)

if type(sh) ~= "table" then
	pcall(function()
		sh = rawget(_G, "shared")
	end)
end

local key = "__lt_ui_protector"
local hosts = {}

local function host(t)
	if type(t) ~= "table" then
		return
	end

	for _, v in hosts do
		if v == t then
			return
		end
	end

	hosts[#hosts + 1] = t
end

host(sh)
host(env)
pcall(function()
	host(_G)
	host(rawget(_G, "shared"))
end)

local function cached()
	for _, h in hosts do
		local ok, v = pcall(rawget, h, key)
		if ok and type(v) == "table" and rawget(v, "ready") == true and rawget(v, "build") == build and rawget(v, "patch") == patch then
			return v
		end
	end
end

local old = cached()
if old then
	if type(old.installGetHuiOverride) == "function" then
		pcall(old.installGetHuiOverride)
	end
	return old
end

for _, h in hosts do
	local ok, v = pcall(rawget, h, key)
	if ok and type(v) == "table" then
		pcall(function()
			if type(v.cleanup) == "function" then
				v.cleanup()
			end
		end)
		pcall(function()
			if type(v.restore) == "function" then
				v.restore()
			end
		end)
	end
end

local UIP = {}
local st = {
	hui = nil,
	screen = nil,
	raw = nil,
	loop = false,
	installed = false,
	cons = setmetatable({}, { __mode = "k" }),
	tracked = setmetatable({}, { __mode = "k" }),
	funcs = {},
	native = {},
	names = {},
}

pcall(function()
	st.funcs.gethui = gethui
	st.funcs.gethiddenui = gethiddenui
	st.funcs.gethiddengui = gethiddengui
	st.funcs.get_hidden_ui = get_hidden_ui
	st.funcs.get_hidden_gui = get_hidden_gui
	st.funcs.cloneref = cloneref
	st.funcs.compareinstances = compareinstances
	st.funcs.protect_gui = protect_gui
	st.funcs.protectgui = protectgui
	st.funcs.protect_ui = protect_ui
	st.funcs.protectui = protectui
	st.funcs.getrenv = getrenv
end)

local function inst(v)
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

local function func(name)
	local v = st.funcs[name]
	if type(v) == "function" then
		return v
	end

	if type(env) == "table" then
		v = rawget(env, name)
		if type(v) == "function" then
			st.funcs[name] = v
			return v
		end
	end

	pcall(function()
		if type(_G) == "table" then
			v = rawget(_G, name)
		end
	end)

	if type(v) == "function" then
		st.funcs[name] = v
		return v
	end

	local gr = st.funcs.getrenv
	if type(gr) == "function" then
		local renv = call(gr)
		if type(renv) == "table" then
			v = rawget(renv, name)
			if type(v) == "function" then
				st.funcs[name] = v
				return v
			end
		end
	end
end

st.native.gethui = func("gethui")
st.native.gethiddenui = func("gethiddenui")
st.native.gethiddengui = func("gethiddengui")
st.native.get_hidden_ui = func("get_hidden_ui")
st.native.get_hidden_gui = func("get_hidden_gui")

local function clone(v)
	local f = func("cloneref")
	if type(f) == "function" and inst(v) then
		local ok, ret = pcall(f, v)
		if ok and ret ~= nil then
			return ret
		end
	end
	return v
end

local function svc(name)
	local ok, ret = pcall(function()
		return clone(game:GetService(name))
	end)
	if ok and inst(ret) then
		return ret
	end
end

local function isa(v, class)
	if not inst(v) then
		return false
	end
	local ok, ret = pcall(function()
		return v:IsA(class)
	end)
	return ok and ret == true
end

local function same(a, b)
	if a == b then
		return true
	end

	local f = func("compareinstances")
	if type(f) == "function" and inst(a) and inst(b) then
		local ok, ret = pcall(f, a, b)
		if ok then
			return ret == true
		end
	end

	return false
end

local function prop(obj, p)
	local ok, ret = pcall(function()
		return obj[p]
	end)
	if ok then
		return ret
	end
end

local function set(obj, p, v)
	pcall(function()
		obj[p] = v
	end)
end

local function con(obj, c)
	if not c then
		return
	end

	local t = st.cons[obj]
	if not t then
		t = {}
		st.cons[obj] = t
	end

	t[#t + 1] = c
end

local function clear(obj)
	local t = st.cons[obj]
	if t then
		for _, c in t do
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	st.cons[obj] = nil
	st.tracked[obj] = nil
end

local function guid()
	local h = svc("HttpService")
	if inst(h) then
		local ok, ret = pcall(function()
			return h:GenerateGUID(false)
		end)
		if ok and type(ret) == "string" and ret ~= "" then
			return ret
		end
	end
end

local function weird()
	local marks = {"̶", "̷", "̸", "̹", "̺", "̻", "͓", "͔", "͘", "͜", "͞", "͟", "͢"}
	local out = {}
	for _ = 1, math.random(10, 20) do
		out[#out + 1] = string.char(math.random(32, 126))
		if math.random() < 0.5 then
			for _ = 1, math.random(1, 4) do
				out[#out + 1] = marks[math.random(#marks)]
			end
		end
	end
	if utf8 and type(utf8.char) == "function" and math.random() < 0.2 then
		out[#out + 1] = utf8.char(0x202E)
	end
	out[#out + 1] = "\0"
	return table.concat(out)
end

function UIP.randomString(keyName)
	local oldName = st.names[keyName or ""]
	if type(oldName) == "string" and oldName ~= "" then
		return oldName
	end

	local g = guid()
	local ret = ((type(g) == "string" and g .. "_" or "") .. weird())
	st.names[keyName or ""] = ret
	return ret
end

function UIP.setSessionNameProvider(fn)
	if type(fn) == "function" then
		st.nameProvider = fn
	else
		st.nameProvider = nil
	end
end

function UIP.getSessionInstanceName(k)
	if type(st.nameProvider) == "function" then
		local ok, ret = pcall(st.nameProvider, k)
		if ok and type(ret) == "string" and ret ~= "" then
			return ret
		end
	end
	return UIP.randomString(k)
end

function UIP.has(name)
	return type(func(name)) == "function"
end

function UIP.getFunction(name)
	return func(name)
end

function UIP.nativeProtect(obj)
	if not inst(obj) then
		return obj
	end

	for _, name in {"protect_gui", "protectgui", "protect_ui", "protectui"} do
		local f = func(name)
		if type(f) == "function" then
			pcall(f, obj)
		end
	end

	return obj
end

function UIP.setTableReadonly(t, v)
	local f = func("setreadonly")
	if type(t) == "table" and type(f) == "function" then
		pcall(f, t, v ~= false)
	end
	return t
end

local function rawHui()
	for _, f in {st.native.gethui, st.native.gethiddenui, st.native.gethiddengui, st.native.get_hidden_ui, st.native.get_hidden_gui} do
		local ret = clone(call(f))
		if inst(ret) and not same(ret, st.hui) and not same(ret, st.screen) then
			st.raw = ret
			return ret
		end
	end
	return st.raw
end

function UIP.rawHuiGrabber()
	return rawHui()
end

local function baseParent()
	local cg = svc("CoreGui")
	if inst(cg) then
		local rb = call(function()
			return cg:FindFirstChild("RobloxGui")
		end)
		if inst(rb) then
			return rb
		end
		return cg
	end

	local raw = rawHui()
	if inst(raw) and not isa(raw, "ScreenGui") then
		return raw
	end

	local ps = svc("Players")
	local lp = inst(ps) and clone(ps.LocalPlayer) or nil
	if inst(lp) then
		local pg = call(function()
			return lp:FindFirstChildWhichIsA("PlayerGui")
		end)
		if inst(pg) then
			return pg
		end
	end
end

function UIP.getBaseParent()
	return baseParent()
end

local role = "__lt_ui_protector_role"
local mark = "__lt_ui_protector_key"
local rootKey = "old-na-method-custom-hui-v1"

local function tag(obj, r)
	pcall(function()
		obj:SetAttribute(role, r)
	end)
	pcall(function()
		obj:SetAttribute(mark, rootKey)
	end)
	return obj
end

local function tagged(obj, r)
	local ok1, a = pcall(function()
		return obj:GetAttribute(role)
	end)
	local ok2, b = pcall(function()
		return obj:GetAttribute(mark)
	end)
	return ok1 and ok2 and a == r and b == rootKey
end

local function find(parent, class, r)
	if not inst(parent) then
		return nil
	end

	local kids = call(function()
		return parent:GetChildren()
	end)
	if type(kids) ~= "table" then
		return nil
	end

	for _, child in kids do
		if inst(child) and isa(child, class) and tagged(child, r) then
			return child
		end
	end
end

local function screenDefaults(gui)
	pcall(function()
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	end)
	pcall(function()
		gui.DisplayOrder = 2147483647
	end)
	pcall(function()
		gui.ResetOnSpawn = false
	end)
	pcall(function()
		gui.IgnoreGuiInset = true
	end)
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
end

local function enforce(obj, props)
	if not inst(obj) then
		return false
	end

	for p, v in props do
		if p == "Parent" then
			if not same(prop(obj, p), v) then
				set(obj, p, v)
			end
		elseif prop(obj, p) ~= v then
			set(obj, p, v)
		end
	end

	return true
end

local function loop()
	if st.loop then
		return
	end

	st.loop = true
	task.spawn(function()
		while st.loop do
			local any = false
			for obj, props in st.tracked do
				if inst(obj) and type(props) == "table" then
					any = true
					enforce(obj, props)
				else
					st.tracked[obj] = nil
					st.cons[obj] = nil
				end
			end

			if not any then
				st.loop = false
				break
			end

			task.wait(0.75)
		end
	end)
end

local function lock(obj, props)
	if not inst(obj) or type(props) ~= "table" then
		return obj
	end

	clear(obj)
	st.tracked[obj] = props
	enforce(obj, props)

	for p in props do
		local ok, sig = pcall(function()
			return obj:GetPropertyChangedSignal(p)
		end)
		if ok and sig then
			con(obj, sig:Connect(function()
				enforce(obj, props)
			end))
		end
	end

	pcall(function()
		con(obj, obj.AncestryChanged:Connect(function()
			enforce(obj, props)
		end))
	end)

	pcall(function()
		con(obj, obj.Destroying:Connect(function()
			clear(obj)
		end))
	end)

	loop()
	return obj
end

function UIP.lockInstance(obj, props)
	return lock(obj, props)
end

function UIP.getCustomHui(parent)
	parent = inst(parent) and parent or baseParent()
	if not inst(parent) then
		return nil
	end

	if inst(st.hui) and same(st.hui.Parent, parent) then
		return st.hui
	end

	local oldFolder = find(parent, "Folder", "hui")
	if inst(oldFolder) then
		st.hui = oldFolder
	else
		st.hui = Instance.new("Folder")
		tag(st.hui, "hui")
	end

	UIP.nativeProtect(st.hui)
	local nm = UIP.getSessionInstanceName("hui")
	return lock(st.hui, {
		Name = nm,
		Parent = parent,
	})
end

function UIP.huiGrabber()
	return UIP.getCustomHui()
end

function UIP.parent()
	return UIP.huiGrabber()
end

function UIP.getScreenGui(name)
	local parent = UIP.huiGrabber()
	if not inst(parent) then
		return nil
	end

	if inst(st.screen) and same(st.screen.Parent, parent) then
		return st.screen
	end

	local oldGui = find(parent, "ScreenGui", "screen")
	if inst(oldGui) then
		st.screen = oldGui
	else
		st.screen = Instance.new("ScreenGui")
		tag(st.screen, "screen")
	end

	screenDefaults(st.screen)
	UIP.nativeProtect(st.screen)
	return lock(st.screen, {
		Name = type(name) == "string" and name ~= "" and name or UIP.getSessionInstanceName("screen"),
		Parent = parent,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 2147483647,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	})
end

function UIP.resolveParent(opts)
	opts = type(opts) == "table" and opts or {}
	local ret = call(opts.parentResolver)
	if inst(ret) then
		return clone(ret)
	end
	if inst(opts.parent) then
		return clone(opts.parent)
	end
	return UIP.huiGrabber()
end

function UIP.protectUI(gui, opts)
	if not inst(gui) then
		return nil
	end

	opts = type(opts) == "table" and opts or {}
	UIP.nativeProtect(gui)

	if isa(gui, "ScreenGui") then
		local target = UIP.resolveParent(opts)
		if not inst(target) then
			return nil
		end

		screenDefaults(gui)
		local props = {
			Parent = target,
			ZIndexBehavior = Enum.ZIndexBehavior.Global,
			DisplayOrder = 2147483647,
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
		}

		if opts.keepName ~= true then
			props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or UIP.randomString(gui)
		end

		return lock(gui, props)
	end

	local target = UIP.getScreenGui()
	if not inst(target) then
		return nil
	end

	local props = {
		Parent = target,
	}

	if opts.lockName == true or opts.keepName ~= true then
		props.Name = type(opts.name) == "string" and opts.name ~= "" and opts.name or UIP.randomString(gui)
	end

	return lock(gui, props)
end

function UIP.protectName(obj, p)
	if not inst(obj) then
		return nil
	end

	local name = UIP.randomString(obj)
	pcall(function()
		obj[p or "Name"] = name
	end)
	return obj
end

function UIP.protectInstance(obj, opts)
	return UIP.protectUI(obj, opts)
end

function UIP.protectCachedInternal(obj, opts)
	return UIP.protectUI(obj, opts)
end

function UIP.harden(obj, opts)
	if not inst(obj) then
		return obj
	end

	opts = type(opts) == "table" and opts or {}
	if opts.rename == true then
		UIP.protectName(obj)
	end

	if opts.deep == true then
		local desc = call(function()
			return obj:GetDescendants()
		end)
		if type(desc) == "table" then
			local n = math.min(#desc, tonumber(opts.limit) or 250)
			for i = 1, n do
				UIP.protectName(desc[i])
				if i % 50 == 0 then
					task.wait()
				end
			end
		end
	end

	return obj
end

function UIP.installGetHuiOverride()
	local function custom()
		return UIP.huiGrabber()
	end

	local names = {"gethui", "gethiddenui", "gethiddengui", "get_hidden_ui", "get_hidden_gui"}
	local okAny = false

	pcall(function()
		gethui = custom
		gethiddenui = custom
		gethiddengui = custom
		get_hidden_ui = custom
		get_hidden_gui = custom
		okAny = true
	end)

	local function apply(t)
		if type(t) ~= "table" then
			return false
		end
		for _, name in names do
			rawset(t, name, custom)
		end
		return true
	end

	pcall(function()
		if type(getgenv) == "function" then
			okAny = apply(getgenv()) or okAny
		end
	end)
	pcall(function()
		okAny = apply(_G) or okAny
	end)

	st.installed = okAny
	UIP.getHuiOverrideInstalled = okAny
	return okAny
end

function UIP.install()
	return UIP.installGetHuiOverride()
end

function UIP.restore()
	local n = st.native
	pcall(function()
		gethui = n.gethui
		gethiddenui = n.gethiddenui
		gethiddengui = n.gethiddengui
		get_hidden_ui = n.get_hidden_ui
		get_hidden_gui = n.get_hidden_gui
	end)

	local function apply(t)
		if type(t) ~= "table" then
			return
		end
		rawset(t, "gethui", n.gethui)
		rawset(t, "gethiddenui", n.gethiddenui)
		rawset(t, "gethiddengui", n.gethiddengui)
		rawset(t, "get_hidden_ui", n.get_hidden_ui)
		rawset(t, "get_hidden_gui", n.get_hidden_gui)
	end

	pcall(function()
		if type(getgenv) == "function" then
			apply(getgenv())
		end
	end)
	pcall(function()
		apply(_G)
	end)

	st.installed = false
	UIP.getHuiOverrideInstalled = false
end

function UIP.cleanup(obj)
	if inst(obj) then
		clear(obj)
		return
	end

	for o in st.cons do
		clear(o)
	end
	for o in st.tracked do
		st.tracked[o] = nil
	end
	st.loop = false
end

function UIP.destroy()
	UIP.cleanup()
	UIP.restore()
	pcall(function()
		if inst(st.screen) then
			st.screen:Destroy()
		end
	end)
	pcall(function()
		if inst(st.hui) then
			st.hui:Destroy()
		end
	end)
	st.screen = nil
	st.hui = nil
end

function UIP.support()
	local out = {}
	for _, name in {"gethui", "gethiddenui", "gethiddengui", "get_hidden_ui", "get_hidden_gui", "cloneref", "compareinstances", "protect_gui", "protectgui", "protect_ui", "protectui"} do
		out[name] = UIP.has(name)
	end
	return out
end

function UIP.status()
	local raw = rawHui()
	local parent = UIP.huiGrabber()
	local screen = UIP.getScreenGui()
	local tracked = 0
	for o in st.tracked do
		if inst(o) then
			tracked += 1
		end
	end
	return {
		build = build,
		patch = patch,
		raw = raw,
		rawClass = inst(raw) and raw.ClassName or nil,
		parent = parent,
		parentClass = inst(parent) and parent.ClassName or nil,
		screen = screen,
		screenClass = inst(screen) and screen.ClassName or nil,
		installed = st.installed,
		tracked = tracked,
		support = UIP.support(),
	}
end

UIP.ready = true
UIP.build = build
UIP.patch = patch

pcall(function()
	UIP.installGetHuiOverride()
end)

for _, h in hosts do
	pcall(rawset, h, key, UIP)
end

return UIP
