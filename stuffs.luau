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

if getgenv().sexyStuff69 then return end
pcall(function() getgenv().sexyStuff69 = true end)

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
local function safeCall(fn, ...)
	if type(fn) ~= "function" then
		local reportedType = typeof and typeof(fn) or type(fn);
		warn("[safeCall] Expected function, got " .. reportedType);
		return nil, "invalid callback";
	end;
	local args = pack(...);
	local results = pack(xpcall(function()
		return fn(unpack(args, 1, args.n));
	end, function(err)
		local trace = debug.traceback("[safeCall] " .. tostring(err), 2);
		warn(trace);
		return trace;
	end));
	if results[1] then
		return unpack(results, 2, results.n);
	end;
	return nil, results[2];
end;
local cloneRef = type(cloneref) == "function" and cloneref or nil;
local runService = __lt.cs("RunService", cloneRef);
local playersService = __lt.cs("Players", cloneRef);
local coreGuiService = __lt.cs("CoreGui", cloneRef);
local starterGuiService = __lt.cs("StarterGui", cloneRef);
local localPlayer = playersService and playersService.LocalPlayer;
repeat
	task.wait();
	localPlayer = playersService and playersService.LocalPlayer;
until localPlayer;
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
local function getRoot(char)
	local rec, model = bodyGrab.ensure(char);
	if not rec then
		return nil;
	end;
	return rec.root or (model and bodyGrab.firstPart(model)) or nil;
end;
local function getTorso(char)
	local rec, model = bodyGrab.ensure(char);
	if not rec then
		return nil;
	end;
	return rec.torso or (model and bodyGrab.firstPart(model)) or nil;
end;
local function getHead(char)
	local rec, model = bodyGrab.ensure(char);
	if not rec then
		return nil;
	end;
	return rec.head or (model and bodyGrab.firstPart(model)) or nil;
end;
local function getChar()
	local plr = playersService and playersService.LocalPlayer;
	local _, model = bodyGrab.ensure(plr);
	return model;
end;
local function getPlrChar(plr)
	return bodyGrab.asChar(plr) or plr or nil;
end;
local function getHumanoid(char)
	local rec, model = bodyGrab.ensure(char or getChar());
	if not model then
		return nil;
	end;
	return rec and rec.humanoid or nil;
end;
local function getHum()
	return getHumanoid(getChar());
end;
local function getPlrHum(pp)
	return getHumanoid(pp);
end;
local function validBtn(b)
	return typeof(b) == "Instance" and b:IsA("GuiButton")
end
getgenv().firebtnclick = function(b)
	if not (validBtn(b) and firesignal) then
		return
	end
	if b.MouseButton1Click then
		firesignal(b.MouseButton1Click)
	end
	if b.Activated then
		firesignal(b.Activated)
	end
end
getgenv().firebtnhold = function(b)
	if not (validBtn(b) and firesignal) then
		return
	end
	if b.MouseButton1Down then
		firesignal(b.MouseButton1Down)
	end
end
getgenv().firebtnlift = function(b)
	if not (validBtn(b) and firesignal) then
		return
	end
	if b.MouseButton1Up then
		firesignal(b.MouseButton1Up)
	end
end
getgenv().firebtnall = function(b)
	if not (validBtn(b) and firesignal) then
		return
	end
	getgenv().firebtnhold(b)
	getgenv().firebtnclick(b)
	getgenv().firebtnlift(b)
end
--[[safeCall(function()
	if setfpscap and rs then
		rs.Heartbeat:Connect(function()
			setfpscap(165.01);
		end);
	end;
end);]]
local coreTypes = Enum.CoreGuiType:GetEnumItems()

local function enableCoreGui()
	if not starterGuiService then
		return
	end
	for _, t in ipairs(coreTypes) do
		if t ~= Enum.CoreGuiType.Backpack and t ~= Enum.CoreGuiType.All and t ~= Enum.CoreGuiType.EmotesMenu and t ~= Enum.CoreGuiType.Chat then
			starterGuiService:SetCoreGuiEnabled(t, true)
		end
	end
end

safeCall(function()
	if runService and starterGuiService then
		runService.RenderStepped:Connect(function()
			safeCall(enableCoreGui)
		end)
	end
end)
local desiredLpProps = {
	DevTouchMovementMode = Enum.DevTouchMovementMode.UserChoice,
	DevTouchCameraMode = Enum.DevTouchCameraMovementMode.UserChoice,
	DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice,
	DevComputerCameraMode = Enum.DevComputerCameraMovementMode.UserChoice,
	--CameraMode = Enum.CameraMode.Classic,
	--CameraMaxZoomDistance = math.huge,
	--CameraMinZoomDistance = 0
}

local function applyLpProps(lp)
	if not lp then
		return
	end
	for k, v in pairs(desiredLpProps) do
		if lp[k] ~= v then
			lp[k] = v
		end
	end
end

if runService then
	runService.RenderStepped:Connect(function()
		safeCall(function()
			applyLpProps(localPlayer)
		end)
	end)
end
--[[safeCall(function()
	rs.PreSimulation:Connect(function()
		safeCall(function()
			local c = getChar();
			if c then
				local h = getHum();
				if h then
					local r = h.RigType;
					local head = getHead(c);
					local torso = r == Enum.HumanoidRigType.R6 and getTorso(c) or nil;
					local upperTorso = getTorso(c);
					local rootPart = getRoot(c);
					if head then
						head.CanCollide = false;
					end;
					if torso then
						torso.CanCollide = true;
					end;
					if upperTorso then
						upperTorso.CanCollide = true;
					end;
					if rootPart then
						rootPart.CanCollide = false;
					end;
				end;
			end;
		end);
	end);
end);]]
--[[safeCall(function()
	if coreGuiService and coreGuiService:FindFirstChild("RobloxGui") then
		local nf = coreGuiService.RobloxGui:FindFirstChild("NotificationFrame");
		if nf then
			nf.ChildAdded:Connect(function(f)
				safeCall(function()
					if f:IsA("Frame") then
						for _, btn in ipairs(f:GetChildren()) do
							if btn:IsA("TextButton") then
								local txt = btn.Text:lower();
								if txt == "accept" or txt == "decline" then
									btn:Destroy();
								end;
							end;
						end;
					end;
				end);
			end);
		end;
	end;
end);]]
safeCall(function()
	(loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/DeltaCustomizationModule.luau")))();
	--(loadstring(game:HttpGet("https://pastebin.com/raw/62ZF2Thh")))();
end);
safeCall(function()
	--getgenv().ActivateAprilMode = true;
	--(loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua")))();
	(loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/NA%20testing.lua")))();
	--(loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE/refs/heads/main/executor")))();
	--(loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/refs/heads/main/NAVerPicker.luau")))();
end);
safeCall(function()
	local function setupCharacter(c)
		safeCall(function()
			task.wait(1);
			local h = getPlrHum(c) or getHum();
			local r = getRoot(c);
			if h and r then
				h.AutoJumpEnabled = false;
				--[[h.FallingDown:Connect(function()
					safeCall(function()
						r.Velocity = Vector3.zero;
						h:ChangeState(Enum.HumanoidStateType.GettingUp);
					end);
				end);]]
				h.Jumping:Connect(function(isJumping)
					safeCall(function()
						if isJumping and h:GetState() == Enum.HumanoidStateType.Jumping then
							h:SetStateEnabled(Enum.HumanoidStateType.Climbing, false);
							local v = r.Velocity;
							r.Velocity = Vector3.new(v.X, h.JumpPower * 1.1, v.Z);
							task.delay(0.2, function()
								h:SetStateEnabled(Enum.HumanoidStateType.Climbing, true);
							end);
						end;
					end);
				end);
			end;
		end);
	end;
	local initial = getChar();
	if initial then
		setupCharacter(initial);
	end;
	if localPlayer then
		localPlayer.CharacterAdded:Connect(setupCharacter);
	end;
end);
safeCall(function()
	if runService then
		runService.RenderStepped:Connect(function()
			safeCall(function()
				local c = getChar()
				local h = c and getHumanoid(c)

				if h then
					h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				end

				if localPlayer and localPlayer:FindFirstChildWhichIsA("PlayerGui") then
					local tg = localPlayer.PlayerGui:FindFirstChild("TouchGui")
					local jb = tg and tg:FindFirstChild("JumpButton",true)
					if jb then
						jb.Size = UDim2.new(0, 85, 0, 85)
						jb.Position = UDim2.new(1, -135, 1, -105)
						jb.Visible = true
					end
				end
			end)
		end)
	end
end);
safeCall(function()
	if (identifyexecutor()):lower() == "codex" then
		local codex = gethui and (gethui()):FindFirstChild("Codex");
		while gethui and (not codex) do
			task.wait(0.5);
			codex = (gethui()):FindFirstChild("Codex");
		end;
		if codex then
			local gui = codex:WaitForChild("gui", 5);
			if gui then
				local editor = (gui:WaitForChild("tabs", 5)):WaitForChild("editor", 5);
				local btns = editor:WaitForChild("buttons", 5);
				local cb = btns:FindFirstChildWhichIsA("TextButton");
				if cb then
					local copy = cb:Clone();
					copy.Name = "Copy";
					local img = copy:FindFirstChildWhichIsA("ImageLabel");
					if img then
						img.Image = "rbxassetid://10169282923";
					end;
					copy.Parent = btns;
					copy.LayoutOrder = -1;
					copy.MouseButton1Click:Connect(function()
						safeCall(function()
							local tb = (editor:WaitForChild("contentContainer", 5)):FindFirstChildOfClass("TextBox");
							if tb and setclipboard then
								setclipboard(tb.Text);
							end;
						end);
					end);
				end;
				for _, g in ipairs(codex:GetChildren()) do
					if g:IsA("ScreenGui") then
						g.DisplayOrder = math.huge;
					end;
				end;
				for _, c in ipairs(gui:GetDescendants()) do
					if c.Name:lower() == "content" then
						c.ChildAdded:Connect(function(ch)
							safeCall(function()
								if ch then
									task.defer(function()
										ch:Destroy();
									end);
								end;
							end);
						end);
					end;
				end;
			end;
		end;
	end;
end);
safeCall(function()
	if (identifyexecutor()):lower() == "codex" then
		_G.CodexUiCustomSettings = {
			CodexSpooferImage = 9524079125,
			CodexSpooferText = "Synapse X",
			CodexSpooferPoweredBy = "x.synapse.to",
			FloatingIconColor = Color3.fromRGB(0, 0, 0),
			MainUiBackground = Color3.fromRGB(0, 0, 0),
			IconsOn = Color3.fromRGB(7, 103, 179),
			IconsOff = Color3.fromRGB(100, 100, 100),
			Fade = false
		};
		loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/CodexClickbait.lua"))();
	end;
end);
