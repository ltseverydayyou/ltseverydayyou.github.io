# ServiceResolver.luau and UIprotector.luau

Executor-only Luau helpers.

- `ServiceResolver.luau`: gets Roblox services safely.
- `UIprotector.luau`: gives you a protected UI parent and protects your UI.

## Load

```lua
local SR = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"))()
local UIP = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/UIprotector.luau"))()
```

## Autoexec

Put this in autoexec if you want `stuffs.luau` and `game_checker.luau` to load automatically:

```lua
-- ltseverydayyou's autoexec shit lol
local urls = {
	"https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/stuffs.luau",
	"https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/game_checker.luau",
}

local loaded = {}

local function run(url)
	if loaded[url] then
		return
	end

	loaded[url] = true

	task.spawn(function()
		local okSrc, src = pcall(game.HttpGet, game, url)

		if not okSrc or type(src) ~= "string" or #src == 0 then
			warn("[Loader] failed:", url)
			loaded[url] = nil
			return
		end

		local fn, err = loadstring(src)

		if type(fn) ~= "function" then
			warn("[Loader] compile error:", url, err)
			loaded[url] = nil
			return
		end

		local ok, res = xpcall(fn, function(e)
			return debug.traceback(tostring(e), 2)
		end)

		if not ok then
			warn("[Loader] runtime error:", url, res)
			loaded[url] = nil
		end
	end)
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

for _, url in urls do
	run(url)
end
```

## Proper UI Usage

Create your UI first, then protect it:

```lua
local UIP = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/UIprotector.luau"))()

local gui = Instance.new("ScreenGui")
gui.Name = "MyUI"

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 200)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Parent = gui

UIP.protectUI(gui, {
	name = "MyUI",
	harden = true,
	deep = true,
	watch = true,
})
```

For a single UI object that is not a `ScreenGui`:

```lua
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(160, 40)
button.Text = "Button"

UIP.protectUI(button, {
	lockName = true,
	name = "Button",
	harden = true,
})
```

## ServiceResolver Usage

```lua
local SR = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"))()

local Players = SR.cs("Players", cloneref)
local RunService = SR.gs("RunService")
local CoreGui = SR.cv(game:GetService("CoreGui"))
```

Use `SR.gs("ServiceName")` for normal service grabbing.

Use `SR.cs("ServiceName", cloneref)` when you want a cloned/ref-safe service.

Use `SR.cm("ServiceName", "MethodName", ...)` to call a method on a resolved service.

```lua
local player = SR.cm("Players", "GetPlayerFromCharacter", character)
```

## ServiceResolver Methods

| Method | Use |
| --- | --- |
| `sv(value)` | Checks if `value` is an `Instance`. |
| `fs(name)` | Safe `game:FindService(name)`. |
| `gfs(name)` | Safe `game:GetService(name)`. |
| `ns(name)` | Safe `Instance.new(name)`. |
| `gs(name)` | Main service getter. Returns service/fallback or `nil`. |
| `cv(value)` | Runs `cloneref(value)` if possible. |
| `cs(name, refFn)` | Gets service and passes it through `refFn`. |
| `ig(method)` | Checks if a method name is an allowed child/descendant lookup. |
| `cm(name, method, ...)` | Gets a service and calls `service[method](service, ...)`. |

Allowed `ig()` method names:

```lua
FindFirstChild
WaitForChild
FindFirstChildOfClass
FindFirstChildWhichIsA
FindFirstAncestor
FindFirstAncestorOfClass
FindFirstAncestorWhichIsA
GetChildren
GetDescendants
QueryDescendants
```

## UIprotector Usage

`UIprotector` installs its `gethui` override when loaded.

These names point to `UIP.huiGrabber()` after install:

```lua
gethui
gethiddenui
gethiddengui
get_hidden_ui
get_hidden_gui
```

Get the protected parent:

```lua
local parent = UIP.parent()
```

Get a protected `ScreenGui`:

```lua
local screen = UIP.getScreenGui("MyScreen")
```

Protect an existing `ScreenGui`:

```lua
UIP.protectUI(gui, {
	name = "MyUI",
	keepName = false,
	harden = true,
	deep = true,
	watch = true,
	rename = false,
})
```

Protect an object inside the protected screen:

```lua
UIP.protectUI(frame, {
	lockName = true,
	name = "MainFrame",
	harden = true,
})
```

## `protectUI` Options

| Option | For | Use |
| --- | --- | --- |
| `parent = Instance` | `ScreenGui` | Parent to this instance. |
| `parentResolver = function()` | `ScreenGui` | Function that returns the parent. |
| `name = "Name"` | Any | Name to lock/use. |
| `keepName = true` | `ScreenGui` | Keep current name instead of renaming. |
| `lockName = true` | Non-`ScreenGui` | Lock the object's name. |
| `harden = true` | Any | Set `Archivable = false` and apply hardening. |
| `deep = true` | Any | Harden current descendants. |
| `watch = true` | Any | Harden new descendants. |
| `rename = true` | Any | Randomize hardened object names. |

## UIprotector Methods

| Method | Use |
| --- | --- |
| `has(name)` | Checks if a global/executor function exists. |
| `getFunction(name)` | Returns a global/executor function or `nil`. |
| `setSessionNameProvider(fn)` | Sets custom random-name provider. |
| `getSessionInstanceName(key)` | Gets stable session name for a key. |
| `randomString(key)` | Returns a random protected name. |
| `nativeProtect(obj)` | Runs native `protect_gui/protect_ui` functions if available. |
| `setTableReadonly(tbl, value)` | Calls `setreadonly(tbl, value)` if available. |
| `rawHuiGrabber()` | Gets the original hidden UI before override. |
| `getRawHuiKind()` | Returns `alias`, `screen`, `folder`, `root`, `other`, or `nil`. |
| `getBaseParent()` | Gets `CoreGui.RobloxGui`, `CoreGui`, or `PlayerGui`. |
| `lockInstance(obj, props)` | Locks listed properties and restores them if changed. |
| `harden(obj, opts)` | Sets `Archivable = false`, optional rename/deep/watch. |
| `getCustomHui(parent)` | Gets/creates protected `Folder`. |
| `huiGrabber()` | Main protected UI parent getter. |
| `getScreenGui(name)` | Gets/creates protected `ScreenGui`. |
| `resolveParent(opts)` | Resolves parent from options or hidden UI. |
| `parent()` | Alias for `huiGrabber()`. |
| `protectUI(gui, opts)` | Main method for protecting UI. |
| `protectName(obj, prop)` | Randomizes `prop` or `Name`. |
| `installGetHuiOverride()` | Installs `gethui`/hidden UI overrides. |
| `install()` | Alias for `installGetHuiOverride()`. |
| `restore()` | Restores original hidden UI functions. |
| `cleanup(obj)` | Stops tracking one object. |
| `cleanup()` | Stops all tracking. |
| `destroy()` | Cleans up, restores functions, destroys created containers. |
| `support()` | Returns available executor helper functions. |
| `status()` | Returns current protector state. |

## Common Calls

```lua
local status = UIP.status()
print(status.parentPath, status.screenPath, status.tracked)

local support = UIP.support()
print(support.gethui, support.cloneref, support.protect_gui)

UIP.cleanup(gui)
UIP.restore()
UIP.destroy()
```

## Public Fields

```lua
UIP.ready
UIP.build
UIP.patch
UIP.getHuiOverrideInstalled
```
