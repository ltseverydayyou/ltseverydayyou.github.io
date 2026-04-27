if getgenv().sexyStuff69 then return end
pcall(function() getgenv().sexyStuff69 = true end)

if not game:IsLoaded() then
	game.Loaded:Wait();
end;
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
local _svcCloneref = (type(cloneref) == "function") and cloneref or nil
local umm_SVC = setmetatable({}, {
	__index = function(self, name)
		local ok, svc
		if _svcCloneref then
			ok, svc = pcall(function()
				return _svcCloneref(game:GetService(name))
			end)
		else
			ok, svc = pcall(game.GetService, game, name)
		end
		if ok and svc then
			rawset(self, name, svc)
			return svc
		end
	end
})
local function ClonedService(name)
	return umm_SVC[name]
end
local rs = ClonedService("RunService");
local players = ClonedService("Players");
local coreGui = ClonedService("CoreGui");
local starterGui = ClonedService("StarterGui");
local localPlayer = players and players.LocalPlayer;
repeat
	task.wait();
	localPlayer = players and players.LocalPlayer;
until localPlayer;
local function normChar(obj)
	if not obj then
		return nil;
	end;
	if typeof(obj) ~= "Instance" then
		return nil;
	end;
	if obj:IsA("Player") then
		return obj.Character;
	elseif obj:IsA("Model") then
		return obj;
	end;
	return nil;
end;
local function getRoot(char)
	char = normChar(char);
	if not char then
		return nil;
	end;
	local fallback;
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local name = v.Name:lower();
			if name == "humanoidrootpart" or name == "torso" or name == "uppertorso" or name == "lowertorso" then
				return v;
			elseif not fallback then
				fallback = v;
			end;
		end;
	end;
	return fallback;
end;
local function getTorso(char)
	char = normChar(char);
	if not char then
		return nil;
	end;
	local fallback;
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local name = v.Name:lower();
			if name == "torso" or name == "uppertorso" or name == "lowertorso" or name == "humanoidrootpart" then
				return v;
			elseif not fallback then
				fallback = v;
			end;
		end;
	end;
	return fallback;
end;
local function getHead(char)
	char = normChar(char);
	if not char then
		return nil;
	end;
	local fallback;
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local name = v.Name:lower();
			if name == "head" then
				return v;
			elseif not fallback then
				fallback = v;
			end;
		end;
	end;
	return fallback;
end;
local function getChar()
	local plrs = players or ClonedService("Players");
	if not plrs then
		return nil;
	end;
	local plr = plrs.LocalPlayer;
	return plr and plr.Character or nil;
end;
local function getPlrChar(plr)
	local fix = normChar(plr) or plr or nil;
	return fix;
end;
local function getHumanoid(char)
	char = normChar(char) or getChar();
	if not char then
		return nil;
	end;
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("Humanoid") then
			return v;
		end;
	end;
	return nil;
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
	if not starterGui then
		return
	end
	for _, t in ipairs(coreTypes) do
		if t ~= Enum.CoreGuiType.Backpack and t ~= Enum.CoreGuiType.All and t ~= Enum.CoreGuiType.EmotesMenu and t ~= Enum.CoreGuiType.Chat then
			starterGui:SetCoreGuiEnabled(t, true)
		end
	end
end

safeCall(function()
	if rs and starterGui then
		rs.RenderStepped:Connect(function()
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

if rs then
	rs.RenderStepped:Connect(function()
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
	if coreGui and coreGui:FindFirstChild("RobloxGui") then
		local nf = coreGui.RobloxGui:FindFirstChild("NotificationFrame");
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
	if rs then
		rs.RenderStepped:Connect(function()
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