local ok, ge = pcall(function()
	if type(getgenv) == "function" then
		return getgenv()
	end
end)

if not ok or type(ge) ~= "table" then
	ge = type(_G) == "table" and _G or {}
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

local host = type(sh) == "table" and sh or ge
local old = type(host) == "table" and rawget(host, "__lt_ui_protector_v5")

if type(old) == "table" then
	if type(old.install) == "function" then
		pcall(old.install)
	end
	return old
end

for _, k in ipairs({
	"__lt_ui_protector_v4",
	"__lt_ui_protector",
}) do
	local v = type(host) == "table" and rawget(host, k) or nil
	if type(v) == "table" then
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

local api = {}
local st = {
	fr = nil,
	sg = nil,
	hb = nil,
	ins = false,
	last = 0,
	rate = 0.35,
	cn = setmetatable({}, { __mode = "k" }),
	it = setmetatable({}, { __mode = "k" }),
	lk = setmetatable({}, { __mode = "k" }),
	da = setmetatable({}, { __mode = "k" }),
	nat = {},
	fn = {},
	loc = {},
}

pcall(function()
	st.loc.gethui = gethui
	st.loc.gethiddenui = gethiddenui
	st.loc.gethiddengui = gethiddengui
	st.loc.get_hidden_ui = get_hidden_ui
	st.loc.get_hidden_gui = get_hidden_gui
	st.loc.cloneref = cloneref
	st.loc.compareinstances = compareinstances
	st.loc.setreadonly = setreadonly
	st.loc.isreadonly = isreadonly
	st.loc.protect_gui = protect_gui
	st.loc.protectgui = protectgui
	st.loc.protect_ui = protect_ui
	st.loc.protectui = protectui
	st.loc.getrenv = getrenv
end)

local function inst(v)
	return typeof(v) == "Instance"
end

local function safe(fn, ...)
	if type(fn) ~= "function" then
		return false, nil
	end

	return pcall(fn, ...)
end

local function call(fn, ...)
	local okc, ret = safe(fn, ...)
	if okc then
		return ret
	end

	return nil
end

local function envfn(n)
	local v = st.loc[n]

	if type(v) == "function" then
		return v
	end

	if type(st.fn[n]) == "function" then
		return st.fn[n]
	end

	if type(ge) == "table" then
		v = rawget(ge, n)
		if type(v) == "function" then
			st.fn[n] = v
			return v
		end
	end

	pcall(function()
		if type(_G) == "table" then
			v = rawget(_G, n)
		end
	end)

	if type(v) == "function" then
		st.fn[n] = v
		return v
	end

	local gr = st.loc.getrenv

	if type(gr) ~= "function" and type(ge) == "table" then
		gr = rawget(ge, "getrenv")
	end

	if type(gr) == "function" then
		local renv = call(gr)
		if type(renv) == "table" then
			v = rawget(renv, n)
			if type(v) == "function" then
				st.fn[n] = v
				return v
			end
		end
	end

	return nil
end

function api.has(n)
	return type(envfn(n)) == "function"
end

function api.fn(n)
	return envfn(n)
end

local function cref(v)
	local f = envfn("cloneref")

	if type(f) == "function" and inst(v) then
		local okc, ret = pcall(f, v)
		if okc and ret ~= nil then
			return ret
		end
	end

	return v
end

local function svc(n)
	local okc, ret = pcall(function()
		local s = game:GetService(n)
		return cref(s)
	end)

	if okc and inst(ret) then
		return ret
	end

	return nil
end

local function isa(x, n)
	if not inst(x) then
		return false
	end

	local okc, ret = pcall(function()
		return x:IsA(n)
	end)

	return okc and ret == true
end

local function eq(a, b)
	if a == b then
		return true
	end

	local f = envfn("compareinstances")

	if type(f) == "function" and inst(a) and inst(b) then
		local okc, ret = pcall(f, a, b)
		if okc then
			return ret == true
		end
	end

	return false
end

local function getp(x, p)
	local okc, ret = pcall(function()
		return x[p]
	end)

	if okc then
		return ret
	end

	return nil
end

local function setp(x, p, v)
	pcall(function()
		x[p] = v
	end)
end

local function addcn(x, c)
	if not c then
		return
	end

	local t = st.cn[x]
	if not t then
		t = {}
		st.cn[x] = t
	end

	t[#t + 1] = c
end

local function enum(a, b)
	local okc, ret = pcall(function()
		return Enum[a][b]
	end)

	if okc then
		return ret
	end

	return nil
end

local function ccount()
	local n = 0

	for x in pairs(st.it) do
		if inst(x) then
			n += 1
		end
	end

	return n
end

function api.random()
	local hs = svc("HttpService")

	if inst(hs) and hs.GenerateGUID then
		local okc, ret = pcall(function()
			return hs:GenerateGUID(false)
		end)

		if okc and type(ret) == "string" and ret ~= "" then
			local pre = math.random(1, 3) == 1 and "\0" or ""
			local suf = math.random(1, 3) == 1 and "​" or ""
			return pre .. ret .. suf
		end
	end

	local a = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local n = math.random(18, 32)
	local t = {}

	for i = 1, n do
		local r = math.random(1, #a)
		t[i] = a:sub(r, r)
	end

	if math.random(1, 3) == 1 then
		t[#t + 1] = "\0"
	end

	if math.random(1, 3) == 1 then
		t[#t + 1] = "​"
	end

	return table.concat(t)
end

local function rawhui()
	local f = {
		st.nat.gethui,
		st.nat.gethiddenui,
		st.nat.gethiddengui,
		st.nat.get_hidden_ui,
		st.nat.get_hidden_gui,
		envfn("gethui"),
		envfn("gethiddenui"),
		envfn("gethiddengui"),
		envfn("get_hidden_ui"),
		envfn("get_hidden_gui"),
	}

	for i = 1, #f do
		local ret = cref(call(f[i]))
		if inst(ret) and not eq(ret, st.fr) and not eq(ret, st.sg) then
			return ret
		end
	end

	return nil
end

local function fakehui(x)
	if not inst(x) then
		return true
	end

	if isa(x, "ScreenGui") then
		return true
	end

	local cn = x.ClassName
	local nm = tostring(x.Name or "")

	if cn == "CoreGui" or cn == "PlayerGui" or cn == "StarterGui" then
		return true
	end

	if nm == "RobloxGui" then
		return true
	end

	return false
end

function api.raw()
	return rawhui()
end

function api.base()
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

	local ps = svc("Players")
	local lp = inst(ps) and cref(ps.LocalPlayer) or nil

	if inst(lp) then
		local pg = call(function()
			return lp:FindFirstChildWhichIsA("PlayerGui")
		end)

		if inst(pg) then
			return pg
		end
	end

	return nil
end

local function hb()
	if st.hb then
		return
	end

	local rs = svc("RunService")
	if not (inst(rs) and rs.Heartbeat) then
		return
	end

	st.hb = rs.Heartbeat:Connect(function()
		local now = os.clock()
		if now - st.last < st.rate then
			return
		end

		st.last = now

		local any = false

		for x, cfg in pairs(st.it) do
			if not inst(x) or cfg.dead then
				st.it[x] = nil
				st.lk[x] = nil
				st.da[x] = nil
			else
				any = true

				for p, v in pairs(cfg.props) do
					local cur = getp(x, p)

					if p == "Parent" then
						if inst(v) and not eq(cur, v) then
							setp(x, p, v)
						end
					elseif cur ~= v then
						setp(x, p, v)
					end
				end
			end
		end

		if not any and st.hb then
			pcall(function()
				st.hb:Disconnect()
			end)

			st.hb = nil
		end
	end)
end

function api.native(x)
	if not inst(x) then
		return x
	end

	local names = {
		"protect_gui",
		"protectgui",
		"protect_ui",
		"protectui",
	}

	for i = 1, #names do
		local f = envfn(names[i])
		if type(f) == "function" then
			pcall(f, x)
		end
	end

	return x
end

function api.tbl(t, ro)
	if type(t) ~= "table" then
		return t
	end

	local sr = envfn("setreadonly")

	if type(sr) == "function" then
		pcall(sr, t, ro ~= false)
	end

	return t
end

function api.lock(x, props)
	if not inst(x) or type(props) ~= "table" then
		return x
	end

	for p, v in pairs(props) do
		setp(x, p, v)
	end

	st.it[x] = {
		props = props,
		dead = false,
	}

	if not st.lk[x] then
		st.lk[x] = true

		for p in pairs(props) do
			local okc, sig = pcall(function()
				return x:GetPropertyChangedSignal(p)
			end)

			if okc and sig then
				addcn(x, sig:Connect(function()
					local cfg = st.it[x]
					if not cfg or cfg.dead then
						return
					end

					local v = cfg.props[p]
					local cur = getp(x, p)

					if p == "Parent" then
						if inst(v) and not eq(cur, v) then
							setp(x, p, v)
						end
					elseif cur ~= v then
						setp(x, p, v)
					end
				end))
			end
		end

		pcall(function()
			addcn(x, x.AncestryChanged:Connect(function()
				local cfg = st.it[x]
				if not cfg or cfg.dead then
					return
				end

				local par = cfg.props.Parent
				if inst(par) and not eq(x.Parent, par) then
					setp(x, "Parent", par)
				end
			end))
		end)

		pcall(function()
			addcn(x, x.Destroying:Connect(function()
				local cfg = st.it[x]
				if cfg then
					cfg.dead = true
				end

				st.it[x] = nil
				st.lk[x] = nil
				st.da[x] = nil
			end))
		end)
	end

	hb()
	return x
end

function api.harden(x, opt)
	if not inst(x) then
		return x
	end

	opt = type(opt) == "table" and opt or {}

	pcall(function()
		x.Archivable = false
	end)

	if opt.rename then
		pcall(function()
			x.Name = api.random()
		end)
	end

	if opt.deep then
		local list = call(function()
			return x:GetDescendants()
		end)

		if type(list) == "table" then
			for i = 1, #list do
				local d = list[i]
				if inst(d) then
					pcall(function()
						d.Archivable = false
					end)

					if opt.rename then
						pcall(function()
							d.Name = api.random()
						end)
					end
				end
			end
		end
	end

	if opt.watch and not st.da[x] then
		st.da[x] = true

		pcall(function()
			addcn(x, x.DescendantAdded:Connect(function(d)
				if not inst(d) then
					return
				end

				pcall(function()
					d.Archivable = false
				end)

				if opt.rename then
					pcall(function()
						d.Name = api.random()
					end)
				end
			end))
		end)
	end

	return x
end

function api.folder()
	local raw = rawhui()

	if inst(raw) and not fakehui(raw) then
		if isa(raw, "BasePlayerGui") or isa(raw, "Folder") then
			return raw
		end
	end

	local par = api.base()
	if not inst(par) then
		return nil
	end

	if inst(st.fr) and eq(st.fr.Parent, par) then
		return st.fr
	end

	local f = Instance.new("Folder")
	local nm = api.random()

	api.native(f)

	st.fr = f

	api.lock(f, {
		Name = nm,
		Parent = par,
		Archivable = false,
	})

	return f
end

function api.screen(nm)
	local par = api.folder()
	if not inst(par) then
		return nil
	end

	if inst(st.sg) and eq(st.sg.Parent, par) then
		return st.sg
	end

	local g = Instance.new("ScreenGui")
	st.sg = g

	api.native(g)

	local props = {
		Name = type(nm) == "string" and nm ~= "" and nm or api.random(),
		Parent = par,
		Archivable = false,
		Enabled = true,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2147483647,
	}

	local zb = enum("ZIndexBehavior", "Global")
	if zb then
		props.ZIndexBehavior = zb
	end

	local si = enum("ScreenInsets", "None")
	if si then
		props.ScreenInsets = si
	end

	local sa = enum("SafeAreaCompatibility", "None")
	if sa then
		props.SafeAreaCompatibility = sa
	end

	pcall(function()
		g.ClipToDeviceSafeArea = false
	end)

	pcall(function()
		g.OnTopOfCoreBlur = true
	end)

	api.lock(g, props)
	api.harden(g, {
		deep = false,
		watch = true,
	})

	return g
end

function api.parent()
	return api.folder()
end

function api.mount(x, opt)
	if not inst(x) then
		return nil
	end

	opt = type(opt) == "table" and opt or {}

	local par = inst(opt.parent) and cref(opt.parent) or nil

	if not inst(par) then
		if isa(x, "ScreenGui") then
			par = api.folder()
		else
			par = api.screen()
		end
	end

	if not inst(par) then
		return nil
	end

	api.native(x)

	local props = {
		Parent = par,
		Archivable = false,
	}

	if not opt.keepName then
		props.Name = type(opt.name) == "string" and opt.name ~= "" and opt.name or api.random()
	end

	if isa(x, "ScreenGui") then
		props.Enabled = true
		props.ResetOnSpawn = false
		props.IgnoreGuiInset = true
		props.DisplayOrder = tonumber(opt.displayOrder) or 2147483647

		local zb = enum("ZIndexBehavior", "Global")
		if zb then
			props.ZIndexBehavior = zb
		end

		local si = enum("ScreenInsets", "None")
		if si then
			props.ScreenInsets = si
		end

		local sa = enum("SafeAreaCompatibility", "None")
		if sa then
			props.SafeAreaCompatibility = sa
		end

		pcall(function()
			x.ClipToDeviceSafeArea = false
		end)

		pcall(function()
			x.OnTopOfCoreBlur = true
		end)
	end

	api.lock(x, props)

	if opt.harden ~= false then
		api.harden(x, {
			deep = opt.deep == true,
			watch = opt.watch ~= false,
			rename = opt.rename == true,
		})
	end

	return x
end

function api.protectUI(x, opt)
	return api.mount(x, opt)
end

function api.protectName(x, prop)
	if not inst(x) then
		return nil
	end

	local nm = api.random()

	pcall(function()
		x[prop or "Name"] = nm
	end)

	pcall(function()
		x.Archivable = false
	end)

	return x
end

function api.resolveParent(opt)
	opt = type(opt) == "table" and opt or {}

	local ret = call(opt.parentResolver)
	if inst(ret) then
		return ret
	end

	if inst(opt.parent) then
		return cref(opt.parent)
	end

	return api.folder() or api.base()
end

function api.getCustomHui()
	return api.folder()
end

function api.huiGrabber()
	return api.folder()
end

function api.install()
	if st.ins then
		return true
	end

	local function f()
		return api.folder()
	end

	local ok1 = pcall(function()
		gethui = f
		gethiddenui = f
		gethiddengui = f
		get_hidden_ui = f
		get_hidden_gui = f
	end)

	local function put(t)
		if type(t) ~= "table" then
			return false
		end

		rawset(t, "gethui", f)
		rawset(t, "gethiddenui", f)
		rawset(t, "gethiddengui", f)
		rawset(t, "get_hidden_ui", f)
		rawset(t, "get_hidden_gui", f)

		return true
	end

	local ok2 = pcall(put, ge)
	local ok3 = pcall(put, _G)

	st.ins = ok1 or ok2 or ok3
	return st.ins
end

function api.restore()
	local n = st.nat

	pcall(function()
		gethui = n.gethui
		gethiddenui = n.gethiddenui
		gethiddengui = n.gethiddengui
		get_hidden_ui = n.get_hidden_ui
		get_hidden_gui = n.get_hidden_gui
	end)

	local function put(t)
		if type(t) ~= "table" then
			return
		end

		rawset(t, "gethui", n.gethui)
		rawset(t, "gethiddenui", n.gethiddenui)
		rawset(t, "gethiddengui", n.gethiddengui)
		rawset(t, "get_hidden_ui", n.get_hidden_ui)
		rawset(t, "get_hidden_gui", n.get_hidden_gui)
	end

	pcall(put, ge)
	pcall(put, _G)

	st.ins = false
end

function api.cleanup(x)
	if inst(x) then
		local t = st.cn[x]

		if t then
			for i = 1, #t do
				pcall(function()
					t[i]:Disconnect()
				end)

				t[i] = nil
			end
		end

		st.cn[x] = nil
		st.it[x] = nil
		st.lk[x] = nil
		st.da[x] = nil

		if ccount() <= 0 and st.hb then
			pcall(function()
				st.hb:Disconnect()
			end)

			st.hb = nil
		end

		return
	end

	for obj, t in pairs(st.cn) do
		for i = 1, #t do
			pcall(function()
				t[i]:Disconnect()
			end)

			t[i] = nil
		end

		st.cn[obj] = nil
	end

	for obj in pairs(st.it) do
		st.it[obj] = nil
	end

	for obj in pairs(st.lk) do
		st.lk[obj] = nil
	end

	for obj in pairs(st.da) do
		st.da[obj] = nil
	end

	if st.hb then
		pcall(function()
			st.hb:Disconnect()
		end)

		st.hb = nil
	end
end

function api.destroy()
	api.cleanup()
	api.restore()

	pcall(function()
		if inst(st.sg) then
			st.sg:Destroy()
		end
	end)

	pcall(function()
		if inst(st.fr) then
			st.fr:Destroy()
		end
	end)

	st.sg = nil
	st.fr = nil
end

function api.support()
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

	local t = {}

	for i = 1, #names do
		t[names[i]] = api.has(names[i])
	end

	return t
end

function api.status()
	local raw = rawhui()
	local par = api.folder()
	local sg = api.screen()

	return {
		raw = raw,
		rawClass = inst(raw) and raw.ClassName or nil,
		parent = par,
		parentClass = inst(par) and par.ClassName or nil,
		screen = sg,
		screenClass = inst(sg) and sg.ClassName or nil,
		installed = st.ins,
		tracked = ccount(),
		support = api.support(),
	}
end

pcall(function()
	st.nat.gethui = envfn("gethui")
	st.nat.gethiddenui = envfn("gethiddenui")
	st.nat.gethiddengui = envfn("gethiddengui")
	st.nat.get_hidden_ui = envfn("get_hidden_ui")
	st.nat.get_hidden_gui = envfn("get_hidden_gui")
end)

pcall(function()
	api.install()
end)

if type(host) == "table" then
	rawset(host, "__lt_ui_protector_v5", api)
end

api.tbl(api, true)

return api