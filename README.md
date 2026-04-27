```lua
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

for _, url in ipairs(urls) do
	run(url)
end
```