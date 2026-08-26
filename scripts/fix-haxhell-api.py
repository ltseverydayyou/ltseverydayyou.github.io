from pathlib import Path

path = Path("index.html")
text = path.read_text(encoding="utf-8")

old_search = "https://haxhell.com/api/v1/search/scripts"
new_search = "https://api.haxhell.com/api/v1/search/scripts"
old_list = "https://haxhell.com/api/v1/scripts"
new_list = "https://api.haxhell.com/api/v1/scripts"

assert text.count(old_search) == 1, text.count(old_search)
assert text.count(old_list) == 1, text.count(old_list)
text = text.replace(old_search, new_search).replace(old_list, new_list)

old_parser = '''            if (panelKey === "robloxscripts" || panelKey === "haxhell") {
                const pagination = payload?.pagination || {};
                return {
                    scripts: Array.isArray(payload?.data) ? payload.data : [],
                    maxPages: Math.max(pagination.totalPages || pagination.pages || 1, 1)
                };
            }
'''
new_parser = '''            if (panelKey === "haxhell") {
                const pagination = payload?.pagination || {};
                const currentPage = scriptSearcherState.haxhell?.page || 1;
                const reportedPages = Number(pagination.totalPages ?? pagination.pages);
                const maxPages = Number.isFinite(reportedPages) && reportedPages > 0 ?
                    reportedPages :
                    pagination.hasMore ? currentPage + 1 : currentPage;
                return {
                    scripts: Array.isArray(payload?.data) ? payload.data : [],
                    maxPages: Math.max(maxPages, 1)
                };
            }
            if (panelKey === "robloxscripts") {
                const pagination = payload?.pagination || {};
                return {
                    scripts: Array.isArray(payload?.data) ? payload.data : [],
                    maxPages: Math.max(pagination.totalPages || pagination.pages || 1, 1)
                };
            }
'''

assert old_parser in text
text = text.replace(old_parser, new_parser, 1)
path.write_text(text, encoding="utf-8")

assert new_search in text
assert new_list in text
assert "pagination.hasMore ? currentPage + 1 : currentPage" in text
print("HaxHell integration patched")
