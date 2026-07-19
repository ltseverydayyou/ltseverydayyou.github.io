--!nonstrict
do
	local realGetfenv = getfenv
	local realSetfenv = setfenv
	local realEnv = typeof(realGetfenv) == "function" and realGetfenv(0) or _G
	local realG = _G
	local realDebug = debug
	local realGetgenv = typeof(getgenv) == "function" and getgenv or nil
	local realGetreg = typeof(getreg) == "function" and getreg or nil
	local realLoadstring = typeof(loadstring) == "function" and loadstring or nil
	local realLoad = typeof(load) == "function" and load or nil
	local root
	local ok, reg = pcall(function()
		if realGetreg then
			return realGetreg()
		end
		if typeof(realDebug) == "table" and typeof(realDebug.getregistry) == "function" then
			return realDebug.getregistry()
		end
	end)
	if ok and typeof(reg) == "table" then
		root = rawget(reg, "__nameless_admin_private")
		if typeof(root) ~= "table" then
			root = {}
			rawset(reg, "__nameless_admin_private", root)
		end
	else
		local host
		ok, host = pcall(function()
			return realGetgenv and realGetgenv() or realG
		end)
		if not ok or typeof(host) ~= "table" then
			host = realG
		end
		root = rawget(host, "__nameless_admin_private")
		if typeof(root) ~= "table" then
			root = {}
			rawset(host, "__nameless_admin_private", root)
		end
	end
	local env = rawget(root, "game_checker_runtime")
	if typeof(env) ~= "table" then
		env = {}
		rawset(root, "game_checker_runtime", env)
	end
	local function idx(_, k)
		if k == "_G" or k == "shared" then
			return env
		end
		if k == "getgenv" then
			return function()
				return env
			end
		end
		if typeof(realEnv) == "table" then
			return realEnv[k]
		end
	end
	if rawget(env, "__env_ready") ~= true then
		rawset(env, "__env_ready", true)
		setmetatable(env, {
			__index = idx,
			__newindex = function(_, k, v)
				rawset(env, k, v)
			end,
			__metatable = "protected"
		})
	end
	local function protectedGetgenv()
		return env
	end
	local function protectedGetfenv(target)
		if typeof(realGetfenv) ~= "function" then
			return env
		end
		if target == nil then
			return env
		end
		if typeof(target) == "number" then
			return env
		end
		local good, got = pcall(realGetfenv, target)
		if good then
			if got == realEnv or got == realG then
				return env
			end
			return got
		end
		return env
	end
	local function protectedSetfenv(target, newEnv)
		if typeof(realSetfenv) ~= "function" then
			return target
		end
		if newEnv == nil or newEnv == realEnv or newEnv == realG then
			newEnv = env
		end
		return realSetfenv(target, newEnv)
	end
	local function protectLoader(loader)
		return function(src, chunk, ...)
			local fn, err = loader(src, chunk, ...)
			if typeof(fn) == "function" and typeof(realSetfenv) == "function" then
				pcall(realSetfenv, fn, env)
			end
			return fn, err
		end
	end
	rawset(env, "_G", env)
	rawset(env, "shared", env)
	rawset(env, "getgenv", protectedGetgenv)
	rawset(env, "getfenv", protectedGetfenv)
	rawset(env, "setfenv", protectedSetfenv)
	if realLoadstring then
		rawset(env, "loadstring", protectLoader(realLoadstring))
	end
	if realLoad then
		rawset(env, "load", protectLoader(realLoad))
	end
	if typeof(realSetfenv) == "function" then
		realSetfenv(1, env)
	end
end
if (getgenv()).sexyGameCheck then
	return
end
pcall(function()
	(getgenv()).sexyGameCheck = true
end)
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local HTTP_RETRY_BASE_DELAY: number = 0.75
local HTTP_RETRY_MAX_DELAY: number = 8
local HTTP_RETRY_JITTER: number = 0.35
local HTTP_RETRY_MAX_ATTEMPTS: number = 6

type HttpRetryError = string?

local function cacheBustUrl(url: string): string
	local sep: string = if string.find(url, "?", 1, true) then "&" else "?"
	local stamp: string = tostring(os.clock()):gsub("%D", "")
	return url .. sep .. "_lt_cache_bust=" .. stamp
end

local function getHttpRetryDelay(attempt: number, err: any): number
	local cappedAttempt: number = math.min(attempt, 6)
	local retryDelay: number = math.min(HTTP_RETRY_MAX_DELAY, HTTP_RETRY_BASE_DELAY * (2 ^ math.max(cappedAttempt - 1, 0)))
	local errText: string = string.lower(tostring(err))

	if string.find(errText, "429", 1, true)
		or string.find(errText, "too many requests", 1, true)
		or string.find(errText, "rate limit", 1, true)
	then
		retryDelay = math.max(retryDelay, 2)
	end

	return retryDelay + (math.random() * HTTP_RETRY_JITTER)
end

local function httpGetText(url: string, noCache: boolean?): (string?, HttpRetryError)
	if typeof(url) ~= "string" or url == "" then
		return nil, "invalid url"
	end

	local attempt: number = 0
	local lastErr: HttpRetryError = nil

	while attempt < HTTP_RETRY_MAX_ATTEMPTS do
		attempt += 1
		local target: string = if noCache then cacheBustUrl(url) else url
		local ok: boolean, srcOrErr: any = pcall(game.HttpGet, game, target)

		if ok and typeof(srcOrErr) == "string" and #srcOrErr > 0 then
			return srcOrErr, nil
		end

		if ok then
			lastErr = "HttpGet returned " .. typeof(srcOrErr)
		else
			lastErr = tostring(srcOrErr)
		end

		if attempt < HTTP_RETRY_MAX_ATTEMPTS then
			task.wait(getHttpRetryDelay(attempt, lastErr))
		end
	end

	return nil, lastErr or "HttpGet failed"
end
local function runRemote(url, chunkName, noCache)
	local src, fetchErr = httpGetText(url, noCache)
	if not src then
		warn("[remote] HttpGet failed for:", url, fetchErr)
		return nil, fetchErr
	end
	local fn, compileErr = loadstring(src, chunkName or "@" .. url)
	if typeof(fn) ~= "function" then
		warn("[remote] loadstring failed for:", url, compileErr)
		return nil, compileErr
	end
	local results = table.pack(pcall(fn))
	if not results[1] then
		local runtimeErr = tostring(results[2])
		warn("[remote] runtime failed for:", url, runtimeErr)
		return nil, runtimeErr
	end
	return table.unpack(results, 2, results.n)
end
local __lt = (function()
	local globalEnv = getgenv and getgenv() or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = typeof(sharedEnv) == "table" and sharedEnv or (typeof(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if typeof(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if typeof(loader) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local resolverSource, resolverFetchErr = httpGetText("https://ltseverydayyou.github.io/ServiceResolver.luau")
	if not resolverSource then
		error("Service resolver failed to fetch: " .. tostring(resolverFetchErr))
	end
	local resolver = loader(resolverSource, "@ServiceResolver.luau")
	if typeof(resolver) ~= "function" then
		error("Service resolver failed to compile")
	end
	local loaded = resolver()
	if typeof(loaded) ~= "table" then
		error("Service resolver failed to load")
	end
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded
	end
	return loaded
end)()
local pack = table.pack
local unpack = table.unpack
local function caller(fn, ...)
	if typeof(fn) ~= "function" then
		local rt = typeof(fn)
		warn("[caller] Expected function, got " .. rt)
		return nil, "invalid callback"
	end
	local a = pack(...)
	local r = pack(xpcall(function()
		return fn(unpack(a, 1, a.n))
	end, function(err)
		local message = "[caller] " .. tostring(err)
		local tr = message
		if typeof(debug) == "table" and typeof(debug.traceback) == "function" then
			tr = debug.traceback(message, 2)
		end
		warn(tr)
		return tr
	end))
	if r[1] then
		return unpack(r, 2, r.n)
	end
	return nil, r[2]
end
local cloneRef = typeof(cloneref) == "function" and cloneref or nil
local playersService = __lt.cs("Players", cloneRef)
local workspaceService = __lt.cs("Workspace", cloneRef)
local runService = __lt.cs("RunService", cloneRef)
local promptService = __lt.cs("ProximityPromptService", cloneRef)
local replicatedStorage = __lt.cs("ReplicatedStorage", cloneRef)
local function getLocalCharacter()
	local player = playersService and playersService.LocalPlayer
	return player and player.Character or nil
end
local bodyGrab = (function()
	local globalEnv = getgenv and getgenv() or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = typeof(sharedEnv) == "table" and sharedEnv or (typeof(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_body_grabber")
		if typeof(cached) == "table" then
			return cached
		end
	end
	local T = {}
	local cache = setmetatable({}, {
		__mode = "k"
	})
	local function asChar(obj)
		if not obj or typeof(obj) ~= "Instance" then
			return nil
		end
		if obj:IsA("Player") then
			return obj.Character
		end
		if obj:IsA("Model") then
			return obj
		end
		return nil
	end
	local function firstPart(model)
		if not model then
			return nil
		end
		local q = {
			model
		}
		local qi, qn = 1, 1
		while qi <= qn do
			local inst = q[qi]
			qi += 1
			if inst:IsA("BasePart") then
				return inst
			end
			local children = inst:GetChildren()
			for i = 1, #children do
				qn += 1
				q[qn] = children[i]
			end
		end
		return nil
	end
	local function applyCandidate(rec, inst)
		if not inst then
			return
		end
		if not rec.humanoid and inst:IsA("Humanoid") then
			rec.humanoid = inst
			return
		end
		if not inst:IsA("BasePart") then
			return
		end
		local name = inst.Name:lower()
		if not rec.root and name:find("root", 1, true) then
			rec.root = inst
			return
		end
		if not rec.torso and name:find("torso", 1, true) then
			rec.torso = inst
			return
		end
		if not rec.head and name:find("head", 1, true) then
			rec.head = inst
		end
	end
	local function rebuild(model, rec)
		rec.head = nil
		rec.root = nil
		rec.torso = nil
		rec.humanoid = nil
		if not model then
			rec.dirty = false
			return rec
		end
		local q = {
			model
		}
		local qi, qn = 1, 1
		while qi <= qn do
			local inst = q[qi]
			qi += 1
			applyCandidate(rec, inst)
			if rec.head and rec.root and rec.torso and rec.humanoid then
				break
			end
			local children = inst:GetChildren()
			for i = 1, #children do
				qn += 1
				q[qn] = children[i]
			end
		end
		rec.dirty = false
		return rec
	end
	function T.bindPlayers(service)
		T.playersService = service
	end
	function T.asChar(obj)
		return asChar(obj)
	end
	function T.firstPart(model)
		return firstPart(model)
	end
	function T.ensure(obj)
		local model = asChar(obj)
		if not model and T.playersService and obj == T.playersService.LocalPlayer then
			model = T.playersService.LocalPlayer.Character
		end
		if not model then
			return nil
		end
		local rec = cache[model]
		if not rec then
			rec = {
				dirty = true
			}
			cache[model] = rec
			rec.a = model.DescendantAdded:Connect(function(inst)
				applyCandidate(rec, inst)
			end)
			rec.r = model.DescendantRemoving:Connect(function(inst)
				local removedTracked = false
				if rec.head == inst then
					rec.head = nil
					removedTracked = true
				end
				if rec.root == inst then
					rec.root = nil
					removedTracked = true
				end
				if rec.torso == inst then
					rec.torso = nil
					removedTracked = true
				end
				if rec.humanoid == inst then
					rec.humanoid = nil
					removedTracked = true
				end
				if removedTracked then
					rec.dirty = true
				end
			end)
			rec.c = model.AncestryChanged:Connect(function(_, parent)
				if not parent then
					if rec.a then
						rec.a:Disconnect()
						rec.a = nil
					end
					if rec.r then
						rec.r:Disconnect()
						rec.r = nil
					end
					if rec.c then
						rec.c:Disconnect()
						rec.c = nil
					end
					cache[model] = nil
				end
			end)
		end
		if rec.dirty or rec.humanoid and rec.humanoid.Parent == nil or rec.root and rec.root.Parent == nil or rec.torso and rec.torso.Parent == nil or rec.head and rec.head.Parent == nil then
			rebuild(model, rec)
		end
		return rec, model
	end
	if cacheHost then
		cacheHost.__lt_body_grabber = T
	end
	return T
end)()
bodyGrab.bindPlayers(playersService)
local function getRoot(c)
	local rec, model = bodyGrab.ensure(c or getLocalCharacter())
	if not rec then
		return nil
	end
	return rec.root or model and bodyGrab.firstPart(model) or nil
end
local function getTorso(c)
	local rec, model = bodyGrab.ensure(c or getLocalCharacter())
	if not rec then
		return nil
	end
	return rec.torso or model and bodyGrab.firstPart(model) or nil
end
local function getHead(c)
	local rec, model = bodyGrab.ensure(c or getLocalCharacter())
	if not rec then
		return nil
	end
	return rec.head or model and bodyGrab.firstPart(model) or nil
end
local function getChar()
	local _, model = bodyGrab.ensure(getLocalCharacter())
	return model
end
local function getPlrChar(plr)
	return bodyGrab.asChar(plr)
end
local function getHumanoidFor(c)
	local rec, model = bodyGrab.ensure(c)
	if not model then
		return nil
	end
	return rec and rec.humanoid or nil
end
local function getHum()
	return getHumanoidFor(getChar())
end
local function getPlrHum(p)
	return getHumanoidFor(p)
end
local mods = {
	{
		id = 2443177453,
		u = "https://raw.githubusercontent.com/Waza80/scripts-new/main/BasicallyFNF.lua"
	},
	{
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/the%20rake"
	},
	{
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Delulu%20Office.lua"
	},
	{
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/The%20Maze.lua"
	},
	{
		u = "https://raw.githubusercontent.com/ltseverydayyou/endless-doors/main/endless%20madness%20buster",
		nc = true
	},
	{
		id = 5120885191,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/anime%20ball"
	},
	{
		id = 3168615253,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/AbilityWarsAura.luau"
	},
	{
		id = 3498637623,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/ZSS%20Autofarm.lua"
	},
	{
		id = 3267012194,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/LOCOfficial%20autoplay.luau"
	},
	{
		id = 2380077519,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/SlapAuraSB.luau"
	},
	{
		id = 9671373627,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/SexCraft.lua"
	},
	{
		id = 10258128048,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/FNP%20Autoplayer.luau"
	},
}
for _, m in mods do
	task.spawn(function()
		caller(function()
			if m.id and m.id ~= game.GameId then
				return
			end
			local src, fetchErr = httpGetText(m.u, m.nc)
			if not src then
				warn("[loader] HttpGet failed for:", m.u, fetchErr)
				return
			end
			local fn, err = loadstring(src)
			if not fn then
				warn("[loader] loadstring failed for:", m.u, err)
				return
			end
			fn()
		end)
	end)
end
caller(function()
	if game.GameId == 4367208330 then
		repeat
			task.wait()
		until getChar()
		if not workspaceService or not runService or not playersService then
			return
		end
		local proxy = {}
		local lastTriggered = setmetatable({}, {
			__mode = "k"
		})
		local function isTargetPrompt(prompt)
			return prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent.Name:lower() == "proxypart"
		end
		local function addPrompt(prompt)
			if isTargetPrompt(prompt) then
				proxy[#proxy + 1] = prompt
			end
		end
		local function getPromptPosition(prompt)
			local parent = prompt.Parent
			if not parent then
				return nil
			end
			if parent:IsA("Attachment") then
				return parent.WorldPosition
			end
			if parent:IsA("BasePart") then
				return parent.Position
			end
			local part = parent:FindFirstAncestorWhichIsA("BasePart")
			return part and part.Position or nil
		end
		for _, prompt in workspaceService:QueryDescendants("ProximityPrompt") do
			addPrompt(prompt)
		end
		workspaceService.DescendantAdded:Connect(function(cur)
			caller(addPrompt, cur)
		end)
		local elapsed = 0
		runService.Heartbeat:Connect(function(deltaTime)
			elapsed += deltaTime
			if elapsed < 0.1 then
				return
			end
			elapsed = 0
			caller(function()
				local plr = playersService.LocalPlayer
				local c = plr and plr.Character
				local root = c and getRoot(c)
				if not root then
					return
				end
				local now = os.clock()
				for i = #proxy, 1, -1 do
					local prompt = proxy[i]
					if not prompt.Parent or not prompt:IsDescendantOf(workspaceService) then
						lastTriggered[prompt] = nil
						table.remove(proxy, i)
					else
						local position = getPromptPosition(prompt)
						local previous = lastTriggered[prompt] or 0
						if position and now - previous >= 0.2 then
							local maxDistance = prompt.MaxActivationDistance + 4
							if (position - root.Position).Magnitude <= maxDistance then
								lastTriggered[prompt] = now
								pcall(fireproximityprompt, prompt)
							end
						end
					end
				end
			end)
		end)
	end
end)
caller(function()
	if game.GameId == 3498637623 then
		if not runService or (not playersService) or (not promptService) then
			return
		end
		local fNAZAttrs = {
			"Storage_Killzone",
			"Vent_Killzone",
			"Freezer_Killzone",
			"BloxBull_Killzone",
			"GasGuardian_Killzone",
			"Outside_Killzone",
			"Checkout_Killzone",
			"Office_Killzone",
			"Toilet_Killzone"
		}
		local killParts = {}
		local function neutralizeKillPart(inst)
			if not inst or typeof(inst) ~= "Instance" or (not inst:IsA("BasePart")) then
				return
			end
			local name = inst.Name:lower()
			local parentName = inst.Parent and inst.Parent.Name:lower() or ""
			if not (name:find("killbox", 1, true) or name:find("kickbox", 1, true) or parentName:find("killbox", 1, true) or parentName:find("kickbox", 1, true)) then
				return
			end
			killParts[inst] = true
			pcall(function()
				inst.CanTouch = false
			end)
			pcall(function()
				inst.CanCollide = false
			end)
			pcall(function()
				inst.CanQuery = false
			end)
		end
		local killPartsHooked = false
		local function installKillPartBypass()
			if not workspaceService or killPartsHooked then
				return
			end
			killPartsHooked = true
			for _, inst in workspaceService:QueryDescendants("Instance") do
				neutralizeKillPart(inst)
			end
			workspaceService.DescendantAdded:Connect(function(inst)
				task.defer(function()
					neutralizeKillPart(inst)
				end)
			end)
		end
		local promptHooked = false
		local function installPromptBypass()
			if promptHooked then
				return
			end
			promptHooked = true
			local plr = playersService.LocalPlayer
			pcall(function()
				plr:SetAttribute("PromptDuration", 0)
			end)
			promptService.PromptShown:Connect(function(prompt)
				caller(function()
					if prompt and prompt.Parent then
						prompt.HoldDuration = 0
						prompt.Enabled = true
						if prompt.MaxActivationDistance < 12 then
							prompt.MaxActivationDistance = 12
						end
					end
				end)
			end)
		end
		local function clearFNAZState()
			local fz = workspaceService and workspaceService:FindFirstChild("FNAZ")
			if not fz then
				return
			end
			for _, attr in fNAZAttrs do
				if fz:GetAttribute(attr) then
					pcall(function()
						fz:SetAttribute(attr, false)
					end)
				end
			end
		end
		local function restoreCamera(hum)
			local cam = workspaceService and workspaceService.CurrentCamera
			if not cam then
				return
			end
			for _, child in cam:GetChildren() do
				if child.Name == "Black" or child:IsA("BlurEffect") or child:IsA("ColorCorrectionEffect") then
					pcall(function()
						child:Destroy()
					end)
				end
			end
			if cam.CameraType == Enum.CameraType.Scriptable then
				cam.CameraType = Enum.CameraType.Custom
			end
			if hum and cam.CameraSubject ~= hum then
				cam.CameraSubject = hum
			end
		end
		local function keepFree()
			local c = getChar()
			local root = c and getRoot(c)
			local hum = c and getHumanoidFor(c)
			if root then
				root.Anchored = false
			end
			if c then
				for _, inst in c:QueryDescendants("BasePart") do
					if inst.Anchored then						inst.Anchored = false
					end
				end
			end
			if hum then
				hum.AutoRotate = true
				hum.PlatformStand = false
				hum.Sit = false
				if hum.Health <= 0 and hum.MaxHealth > 0 then
					hum.Health = hum.MaxHealth
				end
				if hum.WalkSpeed <= 0 then
					hum.WalkSpeed = 16
				end
				if hum.JumpPower <= 0 then
					hum.JumpPower = 50
				end
			end
			promptService.Enabled = true
			clearFNAZState()
			restoreCamera(hum)
		end
		installKillPartBypass()
		installPromptBypass()
		task.spawn(function()
			while task.wait(2) do
				caller(function()
					for inst in killParts do
						if inst.Parent then
							neutralizeKillPart(inst)
						else
							killParts[inst] = nil
						end
					end
				end)
			end
		end)
		while task.wait(0.05) do
			caller(keepFree)
		end
	end
end)
caller(function()
	if game.GameId == 4777817887 or game.GameId == 5295074138 then
		task.spawn(function()
			local gv = getgenv()
			gv.visualizer = gv.visualizer or {}
			gv.visualizer.path = {
				workspace:FindFirstChild("Balls", true),
				workspace:FindFirstChild("TrainingBalls", true)
			}
			runRemote("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/AutoParry.lua")
		end)
		local fld = replicatedStorage and replicatedStorage:WaitForChild("Music", 30)
		if not fld then
			return
		end
		local wl = {
			Classic = true,
			Classic_V2 = true,
			["Winter Jam"] = true,
			["Mythical Unrest"] = true
		}
		local vol = 0.2
		local bag = {}
		local bi = 0
		local cur = nil
		local st = {}
		local hookedSounds = setmetatable({}, {
			__mode = "k"
		})
		local lock = false
		local function isSnd(x)
			return typeof(x) == "Instance" and x:IsA("Sound")
		end
		local function stopSnd(s)
			if s and s.Parent then
				pcall(function()
					s:Stop()
				end)
			end
		end
		local function setVol(s)
			if s and s.Parent then
				pcall(function()
					s.Volume = vol
				end)
			end
		end
		local function mkBag()
			bag = {}
			for n in wl do
				bag[(#bag) + 1] = n
			end
			for i = #bag, 2, -1 do
				local j = math.random(1, i)
				bag[i], bag[j] = bag[j], bag[i]
			end
			bi = 0
		end
		local function nextName()
			if #bag == 0 or bi >= (#bag) then
				mkBag()
			end
			bi += 1
			return bag[bi]
		end
		local function findByName(n)
			return fld:FindFirstChild(n, true)
		end
		local function pickAndPlay()
			local n = nextName()
			local s = findByName(n)
			if not isSnd(s) then
				for _ = 1, 6 do
					n = nextName()
					s = findByName(n)
					if isSnd(s) then
						break
					end
				end
			end
			if not isSnd(s) then
				return
			end
			for _, v in fld:QueryDescendants("Sound") do
				if isSnd(v) and wl[v.Name] then
					stopSnd(v)
				end
			end
			setVol(s)
			st[s] = os.clock()
			cur = s
			pcall(function()
				s.TimePosition = 0
			end)
			pcall(function()
				s.Looped = false
			end)
			pcall(function()
				s:Play()
			end)
		end
		local function enforce()
			if lock then
				return
			end
			lock = true
			local ok, err = xpcall(function()
				for s in st do
					if not s.Parent or not s:IsDescendantOf(fld) then
						st[s] = nil
					end
				end
				local list = {}
				local now = os.clock()
				for _, v in fld:QueryDescendants("Sound") do
					if wl[v.Name] then
						setVol(v)
						if v.Playing then
							if not st[v] then
								st[v] = now
							end
							list[#list + 1] = v
						end
					elseif v.Playing then
						stopSnd(v)
					end
				end
				if #list > 1 then
					local keep = list[1]
					local keepTime = st[keep] or 0
					for i = 2, #list do
						local sound = list[i]
						local soundTime = st[sound] or 0
						if soundTime > keepTime then
							keep = sound
							keepTime = soundTime
						end
					end
					for i = 1, #list do
						local sound = list[i]
						if sound ~= keep then
							stopSnd(sound)
						end
					end
					cur = keep
				elseif #list == 1 then
					cur = list[1]
				elseif not (cur and cur.Parent and cur.Playing) then
					cur = nil
					pickAndPlay()
				end
			end, function(runtimeErr)
				return tostring(runtimeErr)
			end)
			lock = false
			if not ok then
				warn("[music] enforce failed:", err)
			end
		end
		local function hookSnd(s)
			if not isSnd(s) or hookedSounds[s] then
				return
			end
			hookedSounds[s] = true
			if wl[s.Name] then
				setVol(s)
			end
			(s:GetPropertyChangedSignal("Playing")):Connect(function()
				if s.Playing then
					st[s] = os.clock()
				end
				task.defer(enforce)
			end)
			s.Ended:Connect(function()
				task.defer(enforce)
			end)
			if s.Stopped then
				s.Stopped:Connect(function()
					task.defer(enforce)
				end)
			end
		end
		for _, v in fld:QueryDescendants("Sound") do
			if isSnd(v) then
				hookSnd(v)
			end
		end
		fld.DescendantAdded:Connect(function(v)
			if isSnd(v) then
				hookSnd(v)
				task.defer(enforce)
			end
		end)
		task.defer(function()
			local seed = os.clock() + tonumber((string.match(tostring(game.JobId), "%d+") or "0"))
			math.randomseed(math.floor(seed * 1000))
			mkBag()
			enforce()
		end)
		task.spawn(function()
			while fld.Parent do
				task.wait(0.25)
				enforce()
			end
		end)
		local rewardsPlayer = playersService and playersService.LocalPlayer
		local pt_claimHooked = {}
		local bp_claimHooked = {}
		local bp_gridHooked = {}
		local function pt_sWait(p, n, t)
			if not p then
				return
			end
			local c = p:FindFirstChild(n)
			if c then
				return c
			end
			local ok, r = pcall(p.WaitForChild, p, n, t or 5)
			if ok then
				return r
			end
		end
		local function pt_getRewardsList()
			if not rewardsPlayer then
				return
			end
			local pg = pt_sWait(rewardsPlayer, "PlayerGui")
			if not pg then
				return
			end
			local g1 = pt_sWait(pg, "PlaytimeRewards")
			if not g1 then
				return
			end
			local g2 = pt_sWait(g1, "PlaytimeRewards")
			if not g2 then
				return
			end
			local page = pt_sWait(g2, "Page")
			if not page then
				return
			end
			local list = pt_sWait(page, "List")
			if not list then
				return
			end
			return pt_sWait(list, "RewardsList")
		end
		local function pt_fireBtn(b)
			if not b or typeof(firesignal) ~= "function" then
				return
			end
			if not b.Visible then
				return
			end
			local ok, sig = pcall(function()
				return b.Activated
			end)
			if ok and sig then
				pcall(firesignal, sig)
			end
		end
		local function pt_hookPair(mainBtn, claimBtn)
			if not (mainBtn and claimBtn) then
				return
			end
			if pt_claimHooked[claimBtn] then
				return
			end
			pt_claimHooked[claimBtn] = true
			local function fireBoth()
				pt_fireBtn(mainBtn)
				pt_fireBtn(claimBtn)
			end
			if claimBtn.Visible and mainBtn.Visible then
				fireBoth()
			end
			(claimBtn:GetPropertyChangedSignal("Visible")):Connect(function()
				if claimBtn.Visible and mainBtn.Visible then
					fireBoth()
				end
			end)
		end
		local function pt_tryHookItem(item)
			if not (item and item:IsA("ImageButton")) then
				return
			end
			local claim = item:FindFirstChild("ClaimButton")
			if not (claim and claim:IsA("ImageButton")) then
				for _, d in item:QueryDescendants("Instance") do
					if d.Name == "ClaimButton" and d:IsA("ImageButton") then
						claim = d
						break
					end
				end
			end
			if claim then
				pt_hookPair(item, claim)
			end
		end
		local pt_listHooked = setmetatable({}, {
			__mode = "k"
		})
		local function pt_setupPlaytimeRewards()
			while true do
				local rl = pt_getRewardsList()
				if rl and not pt_listHooked[rl] then
					pt_listHooked[rl] = true
					for _, item in rl:GetChildren() do
						pt_tryHookItem(item)
					end
					rl.ChildAdded:Connect(function(c)
						pt_tryHookItem(c)
					end)
				end
				task.wait(1)
			end
		end
		local function bp_getGrid()
			if not rewardsPlayer then
				return
			end
			local pg = rewardsPlayer:FindFirstChildOfClass("PlayerGui")
			if not pg then
				return
			end
			local r1 = pg:FindFirstChild("BattlepassPlaytimeRewards")
			if not r1 then
				return
			end
			local pr = r1:FindFirstChild("PlaytimeRewards")
			if not pr then
				return
			end
			local mf = pr:FindFirstChild("MainFrame")
			if not mf then
				return
			end
			return mf:FindFirstChild("Grid")
		end
		local function bp_click(btn)
			if not btn or typeof(firesignal) ~= "function" then
				return
			end
			local ok, sig = pcall(function()
				return btn.Activated
			end)
			if ok and sig then
				pcall(firesignal, sig)
			end
		end
		local function bp_hookSlot(slot)
			if not slot or (not slot:IsA("ImageLabel")) then
				return
			end
			local cf = slot:FindFirstChild("Claim")
			if not (cf and cf:IsA("Frame")) then
				for _, d in slot:QueryDescendants("Instance") do
					if d.Name == "Claim" and d:IsA("Frame") then
						cf = d
						break
					end
				end
			end
			if not cf then
				return
			end
			local btn = cf:FindFirstChild("Claim")
			if not (btn and btn:IsA("ImageButton")) then
				for _, d in cf:QueryDescendants("Instance") do
					if d.Name == "Claim" and d:IsA("ImageButton") then
						btn = d
						break
					end
				end
			end
			if not btn then
				return
			end
			if bp_claimHooked[btn] then
				return
			end
			bp_claimHooked[btn] = true
			local function check()
				if cf.Visible and btn.Visible then
					bp_click(btn)
				end
			end
			if cf.Visible and btn.Visible then
				check()
			end
			(cf:GetPropertyChangedSignal("Visible")):Connect(function()
				if cf.Visible and btn.Visible then
					check()
				end
			end)
		end
		local function bp_setupGrid(grid)
			if bp_gridHooked[grid] then
				return
			end
			bp_gridHooked[grid] = true
			for _, child in grid:GetChildren() do
				if child:IsA("ImageLabel") then
					bp_hookSlot(child)
				end
			end
			grid.ChildAdded:Connect(function(c)
				if c:IsA("ImageLabel") then
					bp_hookSlot(c)
				end
			end)
		end
		local function bp_setupBattlepassRewards()
			task.spawn(function()
				while true do
					local grid = bp_getGrid()
					if grid then
						bp_setupGrid(grid)
					end
					task.wait(1)
				end
			end)
		end
		task.spawn(pt_setupPlaytimeRewards)
		bp_setupBattlepassRewards()
	end
end)
caller(function()
	if game.GameId ~= 245662005 then
		return
	end

	local circleActionModule = replicatedStorage
		and replicatedStorage:FindFirstChild("Module")
		and replicatedStorage.Module:FindFirstChild("UI")
	if not circleActionModule then
		return
	end

	local requireOk, uiModule = pcall(require, circleActionModule)
	if not requireOk or type(uiModule) ~= "table" or type(uiModule.CircleAction) ~= "table" then
		return
	end

	local CircleAction = uiModule.CircleAction
	local env = getgenv()
	local previous = env.__CircleActionInstantV2
	if type(previous) == "table" then
		if type(previous.Originals) == "table" then
			for spec, original in pairs(previous.Originals) do
				if type(spec) == "table" and type(original) == "table" then
					if type(original.Callback) == "function" then
						spec.Callback = original.Callback
					end
					spec.ReleaseCallback = original.ReleaseCallback
					spec.WhilePressedUpdate = original.WhilePressedUpdate
				end
			end
		end
		previous.Process = function(spec)
			return spec
		end
	end

	local state = env.__CircleActionInstantV3
	if type(state) ~= "table" then
		state = {}
		env.__CircleActionInstantV3 = state
	end
	if type(state.Completed) ~= "table" then
		state.Completed = setmetatable({}, {
			__mode = "k"
		})
	end

	local function callTimed(spec, callback, completed, ...)
		if type(callback) ~= "function" then
			return nil
		end
		local originalTimed = spec.Timed
		local args = table.pack(...)
		local results
		spec.Timed = true
		local ok, err = pcall(function()
			results = table.pack(callback(spec, completed, table.unpack(args, 1, args.n)))
		end)
		spec.Timed = originalTimed
		if not ok then
			error(err, 0)
		end
		if not results then
			return nil
		end
		return table.unpack(results, 1, results.n)
	end

	state.HandlePress = function(oldPress, ...)
		local args = table.pack(...)
		local spec = CircleAction.Spec
		if type(spec) ~= "table" or spec.Timed ~= true then
			return oldPress(table.unpack(args, 1, args.n))
		end
		if state.Completed[spec] then
			return
		end
		state.Completed[spec] = true
		spec.Pressed = false
		spec.PressedAt = nil
		spec.Animation = nil
		local ok, err = pcall(function()
			callTimed(spec, spec.Callback, false, table.unpack(args, 1, args.n))
			if type(spec.WhilePressedUpdate) == "function" then
				spec.WhilePressedUpdate(1)
			end
			callTimed(spec, spec.Callback, true, table.unpack(args, 1, args.n))
			if type(spec.ReleaseCallback) == "function" then
				callTimed(spec, spec.ReleaseCallback, true, table.unpack(args, 1, args.n))
			end
		end)
		if not ok then
			state.Completed[spec] = nil
			error(err, 0)
		end
	end

	state.HandleRelease = function(oldRelease, forceRelease, ...)
		local args = table.pack(...)
		local spec = CircleAction.Spec
		if type(spec) == "table" and state.Completed[spec] then
			state.Completed[spec] = nil
			spec.Pressed = false
			spec.PressedAt = nil
			spec.Animation = nil
			if forceRelease then
				spec.ScreenPosition = nil
				CircleAction.Spec = nil
			end
			return
		end
		return oldRelease(forceRelease, table.unpack(args, 1, args.n))
	end

	if type(hookfunction) == "function" then
		if not state.PressHooked and type(CircleAction.Press) == "function" then
			local oldPress
			oldPress = hookfunction(CircleAction.Press, function(...)
				return state.HandlePress(oldPress, ...)
			end)
			state.OldPress = oldPress
			state.PressHooked = true
		end
		if not state.ReleaseHooked and type(CircleAction.Release) == "function" then
			local oldRelease
			oldRelease = hookfunction(CircleAction.Release, function(forceRelease, ...)
				return state.HandleRelease(oldRelease, forceRelease, ...)
			end)
			state.OldRelease = oldRelease
			state.ReleaseHooked = true
		end
	end

	if state.VisualConnection then
		pcall(function()
			state.VisualConnection:Disconnect()
		end)
		state.VisualConnection = nil
	end
	if runService then
		state.VisualConnection = runService.RenderStepped:Connect(function()
			local frame = CircleAction.Frame
			local hold = frame and frame:FindFirstChild("Hold")
			if hold then
				hold.Visible = false
			end
		end)
	end

	env.FastPunchWrapped = env.FastPunchWrapped or setmetatable({}, {
		__mode = "k"
	})
	env.FastPunchGeneration = (env.FastPunchGeneration or 0) + 1
	local generation = env.FastPunchGeneration

	local function patch()
		local debugLibrary = type(debug) == "table" and debug or nil
		local setuv = debugLibrary and debugLibrary.setupvalue or type(setupvalue) == "function" and setupvalue or nil
		if type(setuv) ~= "function" or type(getgc) ~= "function" then
			return 0
		end
		local gcOk, objects = pcall(getgc, true)
		if not gcOk or type(objects) ~= "table" then
			return 0
		end
		local patched = 0
		for _, object in ipairs(objects) do
			if type(object) == "table" and not env.FastPunchWrapped[object] then
				local original = rawget(object, "attemptPunch")
				if type(original) == "function" then
					local upvalueOk = pcall(setuv, original, 1, 0)
					if upvalueOk then
						local replacement = function(...)
							pcall(setuv, original, 1, 0)
							return original(...)
						end
						local assignOk = pcall(function()
							object.attemptPunch = replacement
						end)
						if assignOk then
							env.FastPunchWrapped[object] = true
							patched += 1
						end
					end
				end
			end
		end
		return patched
	end

	env.FastPunchRescan = patch
	patch()
	task.spawn(function()
		for _ = 1, 10 do
			task.wait(3)
			if env.FastPunchGeneration ~= generation then
				return
			end
			patch()
		end
	end)
end)
