do
	local realGetfenv = getfenv
	local realSetfenv = setfenv
	local realEnv = type(realGetfenv) == "function" and realGetfenv(0) or _G
	local realG = _G
	local realDebug = debug
	local realGetgenv = type(getgenv) == "function" and getgenv or nil
	local realGetreg = type(getreg) == "function" and getreg or nil
	local realLoadstring = type(loadstring) == "function" and loadstring or nil
	local realLoad = type(load) == "function" and load or nil
	local root
	local ok, reg = pcall(function()
		if realGetreg then
			return realGetreg()
		end
		if type(realDebug) == "table" and type(realDebug.getregistry) == "function" then
			return realDebug.getregistry()
		end
	end)
	if ok and type(reg) == "table" then
		root = rawget(reg, "__nameless_admin_private")
		if type(root) ~= "table" then
			root = {}
			rawset(reg, "__nameless_admin_private", root)
		end
	else
		local host
		ok, host = pcall(function()
			return realGetgenv and realGetgenv() or realG
		end)
		if not ok or type(host) ~= "table" then
			host = realG
		end
		root = rawget(host, "__nameless_admin_private")
		if type(root) ~= "table" then
			root = {}
			rawset(host, "__nameless_admin_private", root)
		end
	end
	local env = rawget(root, "runtime")
	if type(env) ~= "table" then
		env = {}
		rawset(root, "runtime", env)
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
		if type(realEnv) == "table" then
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
		if type(realGetfenv) ~= "function" then
			return env
		end
		if target == nil then
			return env
		end
		if type(target) == "number" then
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
		if type(realSetfenv) ~= "function" then
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
			if type(fn) == "function" and type(realSetfenv) == "function" then
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
	if type(realSetfenv) == "function" then
		realSetfenv(1, env)
	end
end

if getgenv().sexyGameCheck then return end
pcall(function() getgenv().sexyGameCheck = true end)

if not game:IsLoaded() then
	game.Loaded:Wait();
end;
local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable");
	end;
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau");
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile");
	end;
	local loaded = resolver();
	if type(loaded) ~= "table" then
		error("Service resolver failed to load");
	end;
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded;
	end;
	return loaded;
end)();
local pack = table.pack;
local unpack = table.unpack;
local function caller(fn, ...)
	if type(fn) ~= "function" then
		local rt = typeof and typeof(fn) or type(fn);
		warn("[caller] Expected function, got " .. rt);
		return nil, "invalid callback";
	end;
	local a = pack(...);
	local r = pack(xpcall(function()
		return fn(unpack(a, 1, a.n));
	end, function(err)
		local tr = debug.traceback("[caller] " .. tostring(err), 2);
		warn(tr);
		return tr;
	end));
	if r[1] then
		return unpack(r, 2, r.n);
	end;
	return nil, r[2];
end;
local cloneRef = type(cloneref) == "function" and cloneref or nil;
local playersService = __lt.cs("Players", cloneRef);
local workspaceService = __lt.cs("Workspace", cloneRef);
local runService = __lt.cs("RunService", cloneRef);
local promptService = __lt.cs("ProximityPromptService", cloneRef);
local replicatedStorage = __lt.cs("ReplicatedStorage", cloneRef);
local function getLocalCharacter()
	local player = playersService and playersService.LocalPlayer;
	return player and player.Character or nil;
end;
local bodyGrab = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_body_grabber");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local T = {};
	local cache = setmetatable({}, {
		__mode = "k"
	});
	local function asChar(obj)
		if not obj or typeof(obj) ~= "Instance" then
			return nil;
		end;
		if obj:IsA("Player") then
			return obj.Character;
		end;
		if obj:IsA("Model") then
			return obj;
		end;
		return nil;
	end;
	local function firstPart(model)
		if not model then
			return nil;
		end;
		local q = { model };
		local qi, qn = 1, 1;
		while qi <= qn do
			local inst = q[qi];
			qi += 1;
			if inst:IsA("BasePart") then
				return inst;
			end;
			local children = inst:GetChildren();
			for i = 1, #children do
				qn += 1;
				q[qn] = children[i];
			end;
		end;
		return nil;
	end;
	local function applyCandidate(rec, inst)
		if not inst then
			return;
		end;
		if not rec.humanoid and inst:IsA("Humanoid") then
			rec.humanoid = inst;
			return;
		end;
		if not inst:IsA("BasePart") then
			return;
		end;
		local name = inst.Name:lower();
		if not rec.root and name:find("root", 1, true) then
			rec.root = inst;
			return;
		end;
		if not rec.torso and name:find("torso", 1, true) then
			rec.torso = inst;
			return;
		end;
		if not rec.head and name:find("head", 1, true) then
			rec.head = inst;
		end;
	end;
	local function rebuild(model, rec)
		rec.head = nil;
		rec.root = nil;
		rec.torso = nil;
		rec.humanoid = nil;
		if not model then
			rec.dirty = false;
			return rec;
		end;
		local q = { model };
		local qi, qn = 1, 1;
		while qi <= qn do
			local inst = q[qi];
			qi += 1;
			applyCandidate(rec, inst);
			if rec.head and rec.root and rec.torso and rec.humanoid then
				break;
			end;
			local children = inst:GetChildren();
			for i = 1, #children do
				qn += 1;
				q[qn] = children[i];
			end;
		end;
		rec.dirty = false;
		return rec;
	end;
	function T.bindPlayers(service)
		T.playersService = service;
	end;
	function T.asChar(obj)
		return asChar(obj);
	end;
	function T.firstPart(model)
		return firstPart(model);
	end;
	function T.ensure(obj)
		local model = asChar(obj);
		if not model and T.playersService and obj == T.playersService.LocalPlayer then
			model = T.playersService.LocalPlayer.Character;
		end;
		if not model then
			return nil;
		end;
		local rec = cache[model];
		if not rec then
			rec = {
				dirty = true
			};
			cache[model] = rec;
			rec.a = model.DescendantAdded:Connect(function(inst)
				applyCandidate(rec, inst);
			end);
			rec.r = model.DescendantRemoving:Connect(function(inst)
				local removedTracked = false;
				if rec.head == inst then
					rec.head = nil;
					removedTracked = true;
				end;
				if rec.root == inst then
					rec.root = nil;
					removedTracked = true;
				end;
				if rec.torso == inst then
					rec.torso = nil;
					removedTracked = true;
				end;
				if rec.humanoid == inst then
					rec.humanoid = nil;
					removedTracked = true;
				end;
				if removedTracked then
					rec.dirty = true;
				end;
			end);
			rec.c = model.AncestryChanged:Connect(function(_, parent)
				if not parent then
					if rec.a then
						rec.a:Disconnect();
						rec.a = nil;
					end;
					if rec.r then
						rec.r:Disconnect();
						rec.r = nil;
					end;
					if rec.c then
						rec.c:Disconnect();
						rec.c = nil;
					end;
					cache[model] = nil;
				end;
			end);
		end;
		if rec.dirty
			or (rec.humanoid and rec.humanoid.Parent == nil)
			or (rec.root and rec.root.Parent == nil)
			or (rec.torso and rec.torso.Parent == nil)
			or (rec.head and rec.head.Parent == nil) then
			rebuild(model, rec);
		end;
		return rec, model;
	end;
	if cacheHost then
		cacheHost.__lt_body_grabber = T;
	end;
	return T;
end)();
bodyGrab.bindPlayers(playersService);
local function getRoot(c)
	local rec, model = bodyGrab.ensure(c or getLocalCharacter());
	if not rec then
		return nil;
	end;
	return rec.root or (model and bodyGrab.firstPart(model)) or nil;
end;
local function getTorso(c)
	local rec, model = bodyGrab.ensure(c or getLocalCharacter());
	if not rec then
		return nil;
	end;
	return rec.torso or (model and bodyGrab.firstPart(model)) or nil;
end;
local function getHead(c)
	local rec, model = bodyGrab.ensure(c or getLocalCharacter());
	if not rec then
		return nil;
	end;
	return rec.head or (model and bodyGrab.firstPart(model)) or nil;
end;
local function getChar()
	local _, model = bodyGrab.ensure(getLocalCharacter());
	return model;
end;
local function getPlrChar(plr)
	return bodyGrab.asChar(plr);
end;
local function getHumanoidFor(c)
	local rec, model = bodyGrab.ensure(c);
	if not model then
		return nil;
	end;
	return rec and rec.humanoid or nil;
end;
local function getHum()
	return getHumanoidFor(getChar());
end;
local function getPlrHum(p)
	return getHumanoidFor(p);
end;
local mods = {
	{
		id = 2404080894,
		u = "https://raw.githubusercontent.com/Edulucas2013/Byby-hub/refs/heads/main/Funky%20Friday%20byby%20hub"
	},
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
	--[[{
		id = 5120885191,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/AnimeBallCodes.lua"
	},]]
	{
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/AbilityWarsAura.luau"
	},
	{
		id = 2380077519,
		u = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/SlapAuraSB.luau"
	}
};
for _, m in ipairs(mods) do
	task.spawn(function()
		caller(function()
			if m.id and m.id ~= game.GameId then
				return;
			end;
			local src = game:HttpGet(m.u, m.nc);
			local fn, err = loadstring(src);
			if not fn then
				warn("[loader] loadstring failed for:", m.u, err);
				return;
			end;
			fn();
		end);
	end);
end;
caller(function()
	if game.GameId == 4367208330 then
		repeat
			task.wait();
		until getChar();
		local proxy = {};
		if not workspaceService or (not runService) or (not playersService) then
			return;
		end;
		for _, v in ipairs(workspaceService:GetDescendants()) do
			if v:IsA("ProximityPrompt") and v.Parent and v.Parent.Name:lower() == "proxypart" then
				table.insert(proxy, v);
			end;
		end;
		workspaceService.DescendantAdded:Connect(function(cur)
			caller(function()
				if cur:IsA("ProximityPrompt") and cur.Parent and cur.Parent.Name:lower() == "proxypart" then
					table.insert(proxy, cur);
				end;
			end);
		end);
		runService.RenderStepped:Connect(function()
			caller(function()
				local plr = playersService.LocalPlayer;
				local c = plr and plr.Character;
				local root = c and getRoot(c);
				if not root then
					return;
				end;
				for i = #proxy, 1, -1 do
					local pr = proxy[i];
					if not pr.Parent or (not pr:IsDescendantOf(workspaceService)) then
						table.remove(proxy, i);
					else
						local md = pr.MaxActivationDistance + 4;
						if (pr.Parent.Position - root.Position).Magnitude <= md then
                            fireproximityprompt(pr);
						end;
					end;
				end;
			end);
		end);
	end;
end);
caller(function()
	if game.GameId == 3498637623 then
		if not runService or (not playersService) or (not promptService) then
			return;
		end;
		local function keepFree()
			local c = getChar();
			local root = c and getRoot(c);
			if root then
				root.Anchored = false;
			end;
			promptService.Enabled = true;
		end;

		while task.wait() do
			caller(keepFree);
		end;
	end;
end);
caller(function()
	if game.GameId == 4777817887 or game.GameId == 5295074138 then
		task.spawn(function()
			local gv = getgenv();
			gv.visualizer = gv.visualizer or {};
			gv.visualizer.mode = "VIM";
			gv.visualizer.path = {
				workspace:FindFirstChild("Balls", true),
				workspace:FindFirstChild("TrainingBalls", true)
			};

			(loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/AutoParry.lua")))();
		end);

		local fld = replicatedStorage and replicatedStorage:WaitForChild("Music", 30);
		if not fld then
			return;
		end;
		local wl = {
			Classic = true,
			Classic_V2 = true,
			["Winter Jam"] = true,
			["Mythical Unrest"] = true
		};
		local vol = 0.2;
		local bag = {};
		local bi = 0;
		local cur = nil;
		local st = {};
		local lock = false;
		local function isSnd(x)
			return typeof(x) == "Instance" and x:IsA("Sound");
		end;
		local function stopSnd(s)
			if s and s.Parent then
				pcall(function()
					s:Stop();
				end);
			end;
		end;
		local function setVol(s)
			if s and s.Parent then
				pcall(function()
					s.Volume = vol;
				end);
			end;
		end;
		local function mkBag()
			bag = {};
			for n in pairs(wl) do
				bag[(#bag) + 1] = n;
			end;
			for i = #bag, 2, -1 do
				local j = math.random(1, i);
				bag[i], bag[j] = bag[j], bag[i];
			end;
			bi = 0;
		end;
		local function nextName()
			if #bag == 0 or bi >= (#bag) then
				mkBag();
			end;
			bi += 1;
			return bag[bi];
		end;
		local function findByName(n)
			return fld:FindFirstChild(n, true);
		end;
		local function pickAndPlay()
			local n = nextName();
			local s = findByName(n);
			if not isSnd(s) then
				for _ = 1, 6 do
					n = nextName();
					s = findByName(n);
					if isSnd(s) then
						break;
					end;
				end;
			end;
			if not isSnd(s) then
				return;
			end;
			for _, v in ipairs(fld:GetDescendants()) do
				if isSnd(v) and wl[v.Name] then
					stopSnd(v);
				end;
			end;
			setVol(s);
			st[s] = os.clock();
			cur = s;
			pcall(function()
				s.TimePosition = 0;
			end);
			pcall(function()
				s.Looped = false;
			end);
			pcall(function()
				s:Play();
			end);
		end;
		local function enforce()
			if lock then
				return;
			end;
			lock = true;
			for s in pairs(st) do
				if not s.Parent or not s:IsDescendantOf(fld) then
					st[s] = nil;
				end;
			end;
			local list = {};
			local now = os.clock();
			for _, v in ipairs(fld:GetDescendants()) do
				if isSnd(v) then
					if wl[v.Name] then
						setVol(v);
						if v.Playing then
							if not st[v] then
								st[v] = now;
							end;
							list[(#list) + 1] = v;
						end;
					elseif v.Playing then
						stopSnd(v);
					end;
				end;
			end;
			if #list > 1 then
				local keep = list[1];
				local kt = st[keep] or math.huge;
				for i = 2, #list do
					local a = list[i];
					local at = st[a] or math.huge;
					if at > kt then
						keep, kt = a, at;
					end;
				end;
				for i = 1, #list do
					local a = list[i];
					if a ~= keep then
						stopSnd(a);
					end;
				end;
				cur = keep;
			elseif #list == 1 then
				cur = list[1];
			elseif not (cur and cur.Parent and cur.Playing) then
				cur = nil;
				pickAndPlay();
			end;
			lock = false;
		end;
		local function hookSnd(s)
			if not isSnd(s) then
				return;
			end;
			if wl[s.Name] then
				setVol(s);
			end;
			(s:GetPropertyChangedSignal("Playing")):Connect(function()
				if s.Playing then
					st[s] = os.clock();
				end;
				task.defer(enforce);
			end);
			s.Ended:Connect(function()
				task.defer(enforce);
			end);
			if s.Stopped then
				s.Stopped:Connect(function()
					task.defer(enforce);
				end);
			end;
		end;
		for _, v in ipairs(fld:GetDescendants()) do
			if isSnd(v) then
				hookSnd(v);
			end;
		end;
		fld.DescendantAdded:Connect(function(v)
			if isSnd(v) then
				hookSnd(v);
				task.defer(enforce);
			end;
		end);
		task.defer(function()
			local seed = os.clock() + tonumber((string.match(tostring(game.JobId), "%d+") or "0"));
			math.randomseed(math.floor(seed * 1000));
			mkBag();
			enforce();
		end);
		task.spawn(function()
			while fld.Parent do
				task.wait(0.25);
				enforce();
			end;
		end);

		local rewardsPlayer = playersService and playersService.LocalPlayer;
		local pt_claimHooked = {};
		local bp_claimHooked = {};
		local bp_gridHooked = {};

		local function pt_sWait(p, n, t)
			if not p then
				return;
			end;
			local c = p:FindFirstChild(n);
			if c then
				return c;
			end;
			local ok, r = pcall(p.WaitForChild, p, n, t or 5);
			if ok then
				return r;
			end;
		end;

		local function pt_getRewardsList()
			if not rewardsPlayer then
				return;
			end;
			local pg = pt_sWait(rewardsPlayer, "PlayerGui");
			if not pg then
				return;
			end;
			local g1 = pt_sWait(pg, "PlaytimeRewards");
			if not g1 then
				return;
			end;
			local g2 = pt_sWait(g1, "PlaytimeRewards");
			if not g2 then
				return;
			end;
			local page = pt_sWait(g2, "Page");
			if not page then
				return;
			end;
			local list = pt_sWait(page, "List");
			if not list then
				return;
			end;
			return pt_sWait(list, "RewardsList");
		end;

		local function pt_fireBtn(b)
			if not b or typeof(firesignal) ~= "function" then
				return;
			end;
			if not b.Visible then
				return;
			end;
			local ok, sig = pcall(function()
				return b.Activated;
			end);
			if ok and sig then
				pcall(firesignal, sig);
			end;
		end;

		local function pt_hookPair(mainBtn, claimBtn)
			if not (mainBtn and claimBtn) then
				return;
			end;
			if pt_claimHooked[claimBtn] then
				return;
			end;
			pt_claimHooked[claimBtn] = true;
			local function fireBoth()
				pt_fireBtn(mainBtn);
				pt_fireBtn(claimBtn);
			end;
			if claimBtn.Visible and mainBtn.Visible then
				fireBoth();
			end;
			claimBtn:GetPropertyChangedSignal("Visible"):Connect(function()
				if claimBtn.Visible and mainBtn.Visible then
					fireBoth();
				end;
			end);
		end;

		local function pt_tryHookItem(item)
			if not (item and item:IsA("ImageButton")) then
				return;
			end;
			local claim = item:FindFirstChild("ClaimButton");
			if not (claim and claim:IsA("ImageButton")) then
				for _, d in ipairs(item:GetDescendants()) do
					if d.Name == "ClaimButton" and d:IsA("ImageButton") then
						claim = d;
						break;
					end;
				end;
			end;
			if claim then
				pt_hookPair(item, claim);
			end;
		end;

		local function pt_setupPlaytimeRewards()
			local rl = pt_getRewardsList();
			if not rl then
				return;
			end;
			for _, item in ipairs(rl:GetChildren()) do
				pt_tryHookItem(item);
			end;
			rl.ChildAdded:Connect(function(c)
				pt_tryHookItem(c);
			end);
		end;

		local function bp_getGrid()
			if not rewardsPlayer then
				return;
			end;
			local pg = rewardsPlayer:FindFirstChildOfClass("PlayerGui");
			if not pg then
				return;
			end;
			local r1 = pg:FindFirstChild("BattlepassPlaytimeRewards");
			if not r1 then
				return;
			end;
			local pr = r1:FindFirstChild("PlaytimeRewards");
			if not pr then
				return;
			end;
			local mf = pr:FindFirstChild("MainFrame");
			if not mf then
				return;
			end;
			return mf:FindFirstChild("Grid");
		end;

		local function bp_click(btn)
			if not btn or typeof(firesignal) ~= "function" then
				return;
			end;
			local ok, sig = pcall(function()
				return btn.Activated;
			end);
			if ok and sig then
				pcall(firesignal, sig);
			end;
		end;

		local function bp_hookSlot(slot)
			if not slot or not slot:IsA("ImageLabel") then
				return;
			end;
			local cf = slot:FindFirstChild("Claim");
			if not (cf and cf:IsA("Frame")) then
				for _, d in ipairs(slot:GetDescendants()) do
					if d.Name == "Claim" and d:IsA("Frame") then
						cf = d;
						break;
					end;
				end;
			end;
			if not cf then
				return;
			end;
			local btn = cf:FindFirstChild("Claim");
			if not (btn and btn:IsA("ImageButton")) then
				for _, d in ipairs(cf:GetDescendants()) do
					if d.Name == "Claim" and d:IsA("ImageButton") then
						btn = d;
						break;
					end;
				end;
			end;
			if not btn then
				return;
			end;
			if bp_claimHooked[btn] then
				return;
			end;
			bp_claimHooked[btn] = true;
			local function check()
				if cf.Visible and btn.Visible then
					bp_click(btn);
				end;
			end;
			if cf.Visible and btn.Visible then
				check();
			end;
			cf:GetPropertyChangedSignal("Visible"):Connect(function()
				if cf.Visible and btn.Visible then
					check();
				end;
			end);
		end;

		local function bp_setupGrid(grid)
			if bp_gridHooked[grid] then
				return;
			end;
			bp_gridHooked[grid] = true;
			for _, child in ipairs(grid:GetChildren()) do
				if child:IsA("ImageLabel") then
					bp_hookSlot(child);
				end;
			end;
			grid.ChildAdded:Connect(function(c)
				if c:IsA("ImageLabel") then
					bp_hookSlot(c);
				end;
			end);
		end;

		local function bp_setupBattlepassRewards()
			task.spawn(function()
				while true do
					local grid = bp_getGrid();
					if grid then
						bp_setupGrid(grid);
					end;
					task.wait(1);
				end;
			end);
		end;

		task.spawn(pt_setupPlaytimeRewards);
		bp_setupBattlepassRewards();
	end;
end);
