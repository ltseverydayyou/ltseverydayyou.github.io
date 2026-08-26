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

new_fetch = '''        function getHaxHellReaderUrl(targetUrl) {
            return `https://r.jina.ai/${targetUrl}`;
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
            const response = await fetch(getHaxHellReaderUrl(url.toString()), {
                mode: "cors",
                headers: {
                    "Accept": "application/json"
                }
            });
            if (!response.ok) {
                throw new Error(`HaxHell relay error (${response.status})`);
            }
            const readerPayload = await response.json();
            const content = readerPayload?.data?.content;
            if (typeof content !== "string") {
                throw new Error("HaxHell relay returned an unexpected response.");
            }
            try {
                return JSON.parse(content);
            } catch (error) {
                throw new Error("HaxHell returned invalid JSON through the relay.");
            }
        }
'''

assert old_fetch in text, 'fetchHaxHell block not found'
text = text.replace(old_fetch, new_fetch, 1)

old_raw = '''            if (!scriptBody && rawScriptUrl) {
                try {
                    const resp = await fetch(rawScriptUrl, {
                        mode: "cors"
                    });
                    if (!resp.ok) {
                        throw new Error("Failed to fetch script");
                    }
                    scriptBody = await resp.text();
'''

new_raw = '''            if (!scriptBody && rawScriptUrl) {
                try {
                    const isHaxHellSource = source === "HaxHell" || /^https:\/\/(?:www\.)?haxhell\.com\//i.test(rawScriptUrl);
                    const requestUrl = isHaxHellSource ? getHaxHellReaderUrl(rawScriptUrl) : rawScriptUrl;
                    const resp = await fetch(requestUrl, {
                        mode: "cors",
                        headers: isHaxHellSource ? {
                            "Accept": "application/json"
                        } : undefined
                    });
                    if (!resp.ok) {
                        throw new Error("Failed to fetch script");
                    }
                    if (isHaxHellSource) {
                        const readerPayload = await resp.json();
                        scriptBody = readerPayload?.data?.content;
                    } else {
                        scriptBody = await resp.text();
                    }
'''

assert old_raw in text, 'raw script fetch block not found'
text = text.replace(old_raw, new_raw, 1)

assert 'https://api.haxhell.com/api/v1/' not in text, 'old HaxHell API host still present'
assert 'https://r.jina.ai/' in text
assert 'https://haxhell.com/api/v1/search/scripts' in text
assert 'getHaxHellReaderUrl(rawScriptUrl)' in text
assert 'readerPayload?.data?.content' in text

path.write_text(text, encoding='utf-8')
print('HaxHell Jina relay integration applied')
