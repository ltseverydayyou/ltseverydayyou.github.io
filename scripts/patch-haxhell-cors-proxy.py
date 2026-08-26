from pathlib import Path

path = Path('index.html')
text = path.read_text(encoding='utf-8')

old_fetch = '''        async function fetchHaxHell(query = "", page = 1) {
            const endpoint = query ?
                "https://api.haxhell.com/api/v1/search/scripts" :
                "https://api.haxhell.com/api/v1/scripts";
            const url = new URL(endpoint);
            url.searchParams.set("page", page.toString());
            url.searchParams.set("limit", MAX_SCRIPT_RESULTS.toString());
            url.searchParams.set("sort", "latest");
            if (query) {
                url.searchParams.set("q", query);
            }
            const response = await fetch(url.toString(), {
                mode: "cors"
            });
            if (!response.ok) {
                throw new Error(`HaxHell API error (${response.status})`);
            }
            return response.json();
        }
'''

new_fetch = '''        function getHaxHellProxyUrl(targetUrl) {
            return `https://corsproxy.io/?url=${encodeURIComponent(targetUrl)}`;
        }

        async function fetchHaxHell(query = "", page = 1) {
            const endpoint = query ?
                "https://haxhell.com/api/v1/search/scripts" :
                "https://haxhell.com/api/v1/scripts";
            const url = new URL(endpoint);
            url.searchParams.set("page", page.toString());
            url.searchParams.set("limit", MAX_SCRIPT_RESULTS.toString());
            url.searchParams.set("sort", "latest");
            if (query) {
                url.searchParams.set("q", query);
            }
            const response = await fetch(getHaxHellProxyUrl(url.toString()), {
                mode: "cors",
                headers: {
                    "Accept": "application/json"
                }
            });
            if (!response.ok) {
                throw new Error(`HaxHell API error (${response.status})`);
            }
            return response.json();
        }
'''

assert old_fetch in text, 'fetchHaxHell block not found'
text = text.replace(old_fetch, new_fetch, 1)

old_raw = '''            if (!scriptBody && rawScriptUrl) {
                try {
                    const resp = await fetch(rawScriptUrl, {
                        mode: "cors"
                    });
'''

new_raw = '''            if (!scriptBody && rawScriptUrl) {
                try {
                    const isHaxHellSource = source === "HaxHell" || /(^|\\.)haxhell\\.com$/i.test(new URL(rawScriptUrl).hostname);
                    const requestUrl = isHaxHellSource ? getHaxHellProxyUrl(rawScriptUrl) : rawScriptUrl;
                    const resp = await fetch(requestUrl, {
                        mode: "cors"
                    });
'''

assert old_raw in text, 'raw script fetch block not found'
text = text.replace(old_raw, new_raw, 1)

assert 'https://api.haxhell.com/api/v1/' not in text, 'old HaxHell API host still present'
assert 'https://corsproxy.io/?url=' in text
assert 'https://haxhell.com/api/v1/search/scripts' in text
assert 'getHaxHellProxyUrl(rawScriptUrl)' in text

path.write_text(text, encoding='utf-8')
print('HaxHell CORS proxy integration applied')
