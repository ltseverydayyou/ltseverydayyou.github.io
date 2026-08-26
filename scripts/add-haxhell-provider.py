from pathlib import Path

p = Path("index.html")
s = p.read_text(encoding="utf-8")

s = s.replace("Searches ScriptBlox, Rscripts, and RobloxScripts.com.", "Searches ScriptBlox, Rscripts, RobloxScripts.com, and HaxHell.")

needle = '''                            <button class="script-searcher__tab" id="script-search-tab-robloxscripts" type="button"
                                role="tab" aria-selected="false" aria-controls="script-search-panel-robloxscripts"
                                data-script-search-tab="robloxscripts">
                                RobloxScripts
                            </button>'''
insert = needle + '''
                            <button class="script-searcher__tab" id="script-search-tab-haxhell" type="button"
                                role="tab" aria-selected="false" aria-controls="script-search-panel-haxhell"
                                data-script-search-tab="haxhell">
                                HaxHell
                            </button>'''
assert needle in s
s = s.replace(needle, insert, 1)

needle = '''                            <div class="script-searcher__panel" id="script-search-panel-robloxscripts" role="tabpanel"
                                aria-labelledby="script-search-tab-robloxscripts"
                                data-script-search-panel="robloxscripts">
                                <div class="script-searcher__panel-head">
                                    <div class="script-searcher__panel-head-group">
                                        <h3>RobloxScripts</h3>
                                        <span id="script-search-robloxscripts-meta"></span>
                                    </div>
                                    <div class="script-searcher__panel-controls">
                                        <button type="button" id="script-search-robloxscripts-prev"
                                            aria-label="Previous RobloxScripts page">
                                            Prev
                                        </button>
                                        <span id="script-search-robloxscripts-page"
                                            class="script-searcher__panel-page">
                                            Page 1
                                        </span>
                                        <button type="button" id="script-search-robloxscripts-next"
                                            aria-label="Next RobloxScripts page">
                                            Next
                                        </button>
                                    </div>
                                </div>
                                <div id="script-search-robloxscripts-error" class="script-searcher__error"
                                    aria-live="polite"></div>
                                <div id="script-search-robloxscripts" class="script-searcher__grid"></div>
                            </div>'''
insert = needle + '''
                            <div class="script-searcher__panel" id="script-search-panel-haxhell" role="tabpanel"
                                aria-labelledby="script-search-tab-haxhell" data-script-search-panel="haxhell">
                                <div class="script-searcher__panel-head">
                                    <div class="script-searcher__panel-head-group">
                                        <h3>HaxHell</h3>
                                        <span id="script-search-haxhell-meta"></span>
                                    </div>
                                    <div class="script-searcher__panel-controls">
                                        <button type="button" id="script-search-haxhell-prev"
                                            aria-label="Previous HaxHell page">
                                            Prev
                                        </button>
                                        <span id="script-search-haxhell-page" class="script-searcher__panel-page">
                                            Page 1
                                        </span>
                                        <button type="button" id="script-search-haxhell-next"
                                            aria-label="Next HaxHell page">
                                            Next
                                        </button>
                                    </div>
                                </div>
                                <div id="script-search-haxhell-error" class="script-searcher__error"
                                    aria-live="polite"></div>
                                <div id="script-search-haxhell" class="script-searcher__grid"></div>
                            </div>'''
assert needle in s
s = s.replace(needle, insert, 1)

s = s.replace('''            robloxscripts: {
                page: 1,
                maxPages: 1
            }
        };''', '''            robloxscripts: {
                page: 1,
                maxPages: 1
            },
            haxhell: {
                page: 1,
                maxPages: 1
            }
        };''', 1)

needle = '''            robloxscripts: {
                panelEl: q("#script-search-panel-robloxscripts"),
                tab: q("#script-search-tab-robloxscripts"),
                container: q("#script-search-robloxscripts"),
                meta: q("#script-search-robloxscripts-meta"),
                error: q("#script-search-robloxscripts-error"),
                label: "RobloxScripts",
                pageLabel: q("#script-search-robloxscripts-page"),
                prev: q("#script-search-robloxscripts-prev"),
                next: q("#script-search-robloxscripts-next")
            }'''
insert = needle + ''',
            haxhell: {
                panelEl: q("#script-search-panel-haxhell"),
                tab: q("#script-search-tab-haxhell"),
                container: q("#script-search-haxhell"),
                meta: q("#script-search-haxhell-meta"),
                error: q("#script-search-haxhell-error"),
                label: "HaxHell",
                pageLabel: q("#script-search-haxhell-page"),
                prev: q("#script-search-haxhell-prev"),
                next: q("#script-search-haxhell-next")
            }'''
assert needle in s
s = s.replace(needle, insert, 1)

s = s.replace('''                entry.game?.imageUrl,
                entry.game?.gameLogo''', '''                entry.game?.imageUrl,
                entry.game?.gameLogo,
                entry.game?.thumbnailUrl,
                entry.media?.thumbnailUrl''', 1)

s = s.replace('''            const rawLikes = entry.likes ?? entry.likeCount;
            const rawDislikes = entry.dislikes ?? entry.dislikeCount;''', '''            const rawLikes = entry.likes ?? entry.likeCount ?? entry.stats?.likes;
            const rawDislikes = entry.dislikes ?? entry.dislikeCount ?? entry.stats?.dislikes;''', 1)
s = s.replace('''            const keyRequired = entry.keySystem ?? entry.key ?? entry.accessType === "key";''', '''            const keyRequired = entry.keySystem ?? entry.flags?.keySystem ?? entry.key ?? entry.accessType === "key";''', 1)
s = s.replace('''            const universal = Boolean(entry.isUniversal);
            const patched = Boolean(entry.isPatched);''', '''            const universal = Boolean(entry.isUniversal || entry.type === "universal");
            const patched = Boolean(entry.isPatched || entry.flags?.patched);''', 1)
s = s.replace('''                entry.author?.verified ??
                entry.verified ??''', '''                entry.author?.verified ??
                entry.author?.isScripterVerified ??
                entry.flags?.verified ??
                entry.verified ??''', 1)

s = s.replace('''                entry.scriptPageUrl ||
                entry.url ||
                entry.link ||''', '''                entry.scriptPageUrl ||
                entry.links?.webpage ||
                entry.url ||
                entry.link ||''', 1)
s = s.replace('''                (source === "ScriptBlox" && entry.slug ?
                    `https://scriptblox.com/script/${entry.slug}` :
                    null);''', '''                (source === "ScriptBlox" && entry.slug ?
                    `https://scriptblox.com/script/${entry.slug}` :
                    null) ||
                (source === "HaxHell" && entry.slug ?
                    `https://haxhell.com/scripts/${entry.slug}` :
                    null);''', 1)

s = s.replace('''            const viewsText =
                entry.views ?? entry.viewCount ?? entry.totalViews ?? 0;''', '''            const viewsText =
                entry.views ?? entry.viewCount ?? entry.totalViews ?? entry.stats?.views ?? 0;''', 1)

s = s.replace('''            if (panelKey === "robloxscripts") {
                const pagination = payload?.pagination || {};
                return {
                    scripts: Array.isArray(payload?.data) ? payload.data : [],
                    maxPages: Math.max(pagination.totalPages || pagination.pages || 1, 1)
                };
            }''', '''            if (panelKey === "robloxscripts" || panelKey === "haxhell") {
                const pagination = payload?.pagination || {};
                return {
                    scripts: Array.isArray(payload?.data) ? payload.data : [],
                    maxPages: Math.max(pagination.totalPages || pagination.pages || 1, 1)
                };
            }''', 1)

needle = '''        async function fetchRobloxScripts(query = "", page = 1) {
            const url = new URL("https://robloxscripts.com/api/v1/scripts");
            url.searchParams.set("page", Math.min(Math.max(page, 1), 200).toString());
            url.searchParams.set("limit", MAX_SCRIPT_RESULTS.toString());
            url.searchParams.set("sort", "newest");
            if (query) {
                url.searchParams.set("q", query.slice(0, 100));
            }
            const response = await fetch(url.toString(), {
                mode: "cors"
            });
            if (!response.ok) {
                if (response.status === 429) {
                    throw new Error("RobloxScripts rate limit reached. Try again shortly.");
                }
                if (response.status === 503) {
                    throw new Error("RobloxScripts API is temporarily unavailable.");
                }
                throw new Error(`RobloxScripts API error (${response.status})`);
            }
            return response.json();
        }'''
insert = needle + '''

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
            const response = await fetch(url.toString(), {
                mode: "cors"
            });
            if (!response.ok) {
                throw new Error(`HaxHell API error (${response.status})`);
            }
            return response.json();
        }'''
assert needle in s
s = s.replace(needle, insert, 1)

s = s.replace('''            const rawScriptUrl = entry.rawScript || entry.rawScriptUrl;''', '''            const rawScriptUrl = entry.rawScript || entry.rawScriptUrl || entry.links?.raw;''', 1)

s = s.replace('''                } else if (panelKey === "robloxscripts") {
                    payload = await fetchRobloxScripts(scriptSearcherState.query, page);
                } else {''', '''                } else if (panelKey === "robloxscripts") {
                    payload = await fetchRobloxScripts(scriptSearcherState.query, page);
                } else if (panelKey === "haxhell") {
                    payload = await fetchHaxHell(scriptSearcherState.query, page);
                } else {''', 1)

s = s.replace('''                        panelKey === "robloxscripts" && error instanceof Error ?
                            error.message :
                            "Unable to load scripts.";''', '''                        (panelKey === "robloxscripts" || panelKey === "haxhell") && error instanceof Error ?
                            error.message :
                            "Unable to load scripts.";''', 1)

p.write_text(s, encoding="utf-8")
