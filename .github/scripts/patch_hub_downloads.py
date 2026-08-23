from pathlib import Path

p = Path("index.html")
t = p.read_text(encoding="utf-8")

if 'aria-label="ltseverydayyou Hub downloads"' in t:
    raise SystemExit(0)

marker = '                <section class="mcp-details" aria-label="How Roblox MCP Bridge works">'
if marker not in t:
    raise SystemExit("MCP insertion point not found")

block = '''                <section class="mcp-spotlight" aria-labelledby="hub-download-title">
                    <div class="mcp-spotlight__content">
                        <div class="mcp-spotlight__copy">
                            <p class="mcp-spotlight__eyebrow">Vyperia's Dungeon · Desktop &amp; Mobile</p>
                            <h2 id="hub-download-title">Take the Dungeon with you.</h2>
                            <p class="mcp-spotlight__description">
                                Install the native ltseverydayyou Hub app for Windows or Android. Both builds load the live
                                website interface while adding platform-specific app integration and update support.
                            </p>
                            <div class="mcp-spotlight__tags" aria-label="Supported platforms">
                                <span>Windows</span><span>Android</span><span>Native app</span><span>Auto-updates</span>
                            </div>
                        </div>
                        <div class="mcp-spotlight__actions" aria-label="ltseverydayyou Hub downloads">
                            <a class="mcp-download mcp-download--windows" href="https://github.com/ltseverydayyou/ltseverydayyou.github.io/releases/latest/download/ltseverydayyou-Hub-Windows.exe">
                                <span class="mcp-download__copy"><strong>Windows app</strong><span>Download .exe</span></span>
                                <span class="mcp-download__arrow" aria-hidden="true">↓</span>
                            </a>
                            <a class="mcp-download mcp-download--android" href="https://github.com/ltseverydayyou/ltseverydayyou.github.io/releases/latest/download/ltseverydayyou-Hub.apk">
                                <span class="mcp-download__copy"><strong>Android app</strong><span>Download .apk</span></span>
                                <span class="mcp-download__arrow" aria-hidden="true">↓</span>
                            </a>
                            <div class="mcp-link-row">
                                <a class="mcp-link" href="https://github.com/ltseverydayyou/ltseverydayyou.github.io/releases/latest" target="_blank" rel="noopener noreferrer">View release ↗</a>
                                <a class="mcp-link" href="https://github.com/ltseverydayyou/ltseverydayyou.github.io" target="_blank" rel="noopener noreferrer">GitHub repo ↗</a>
                            </div>
                        </div>
                    </div>
                </section>

'''

p.write_text(t.replace(marker, block + marker, 1), encoding="utf-8")
