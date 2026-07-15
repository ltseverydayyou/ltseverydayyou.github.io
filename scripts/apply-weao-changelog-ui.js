import fs from "node:fs/promises";

const filePath = new URL("../index.html", import.meta.url);
let source = await fs.readFile(filePath, "utf8");

function insertAfter(needle, insertion, marker) {
    if (source.includes(marker)) {
        return;
    }
    if (!source.includes(needle)) {
        throw new Error(`Unable to find insertion point for ${marker}`);
    }
    source = source.replace(needle, `${needle}${insertion}`);
}

function replaceOnce(needle, replacement, marker) {
    if (source.includes(marker)) {
        return;
    }
    if (!source.includes(needle)) {
        throw new Error(`Unable to find replacement point for ${marker}`);
    }
    source = source.replace(needle, replacement);
}

insertAfter(
`        .executor-card__details {
            padding: 0 18px 16px 18px;
            display: grid;
            gap: 12px;
        }
`,
`
        .executor-card__changelog {
            display: grid;
            gap: 10px;
            padding-top: 4px;
        }

        .executor-card__changelog-heading {
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            gap: 12px;
        }

        .executor-card__changelog-title {
            margin: 0;
            color: var(--tx);
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.1em;
            text-transform: uppercase;
        }

        .executor-card__changelog-count {
            color: var(--mu);
            font-size: 11px;
        }

        .executor-card__changelog-list {
            display: grid;
            gap: 8px;
        }

        .executor-card__changelog-entry {
            display: grid;
            gap: 6px;
            padding: 11px 13px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            background: rgba(255, 255, 255, 0.035);
        }

        .executor-card__changelog-meta {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            flex-wrap: wrap;
        }

        .executor-card__changelog-version {
            color: var(--ac);
            font-size: 12px;
            font-weight: 800;
        }

        .executor-card__changelog-date {
            color: var(--mu);
            font-size: 11px;
        }

        .executor-card__changelog-body {
            margin: 0;
            color: rgba(231, 233, 238, 0.84);
            font-size: 13px;
            line-height: 1.55;
            overflow-wrap: anywhere;
            white-space: pre-wrap;
        }
`,
".executor-card__changelog {"
);

insertAfter(
`        const executorCacheUrl = \`\${weaoCacheBase}/executors.json\`;
`,
`        const executorChangelogCacheUrl = \`\${weaoCacheBase}/executor-changelogs.json\`;
`,
"const executorChangelogCacheUrl ="
);

insertAfter(
`        let executorCache = [];
        let executorCacheFetchedAt = null;
`,
`        let executorChangelogCache = null;
        let executorChangelogCacheFetchedAt = null;
`,
"let executorChangelogCache = null;"
);

insertAfter(
`        function getExecutorDescription(executor) {
            const raw = String(executor?.slug?.fullDescription || "").trim();
            if (!raw || /^no description currently available/i.test(raw)) {
                return "";
            }
            return raw;
        }
`,
`
        function getExecutorChangelogRecord(executor) {
            const entries = executorChangelogCache?.entries;
            if (!entries || typeof entries !== "object") {
                return null;
            }

            const identities = [
                executor?.trackerId,
                executor?._id,
                executor?.title
            ].filter((value) => typeof value === "string" && value.trim());
            const keys = Object.keys(entries);

            for (const identity of identities) {
                if (entries[identity]) {
                    return entries[identity];
                }
                const normalized = identity.trim().toLowerCase();
                const matchingKey = keys.find(
                    (key) => key.trim().toLowerCase() === normalized
                );
                if (matchingKey) {
                    return entries[matchingKey];
                }
            }

            return null;
        }

        function getExecutorChangelogTime(entry) {
            const timestamp = Number(entry?.timestamp);
            if (Number.isFinite(timestamp) && timestamp > 0) {
                return timestamp;
            }
            const parsed = Date.parse(entry?.date || "");
            return Number.isFinite(parsed) ? parsed : 0;
        }

        function formatExecutorChangelogDate(entry) {
            const time = getExecutorChangelogTime(entry);
            if (!time) {
                return "";
            }
            return new Intl.DateTimeFormat(undefined, {
                year: "numeric",
                month: "short",
                day: "numeric"
            }).format(new Date(time));
        }

        function createExecutorChangelogSection(executor) {
            const record = getExecutorChangelogRecord(executor);
            const response = record?.changelogs;
            const changelogs = Array.isArray(response?.changelogs) ?
                response.changelogs :
                [];

            if (!changelogs.length) {
                return null;
            }

            const sorted = [...changelogs]
                .filter((entry) => entry && typeof entry === "object")
                .sort((left, right) =>
                    getExecutorChangelogTime(right) - getExecutorChangelogTime(left)
                );
            const visible = sorted.slice(0, 8);

            if (!visible.length) {
                return null;
            }

            const section = document.createElement("section");
            section.className = "executor-card__changelog";

            const heading = document.createElement("div");
            heading.className = "executor-card__changelog-heading";

            const title = document.createElement("h4");
            title.className = "executor-card__changelog-title";
            title.textContent = "Changelog";

            const count = document.createElement("span");
            count.className = "executor-card__changelog-count";
            count.textContent = sorted.length > visible.length ?
                "Latest " + visible.length + " of " + sorted.length :
                sorted.length + " update" + (sorted.length === 1 ? "" : "s");

            heading.append(title, count);

            const list = document.createElement("div");
            list.className = "executor-card__changelog-list";

            visible.forEach((item) => {
                const entry = document.createElement("article");
                entry.className = "executor-card__changelog-entry";

                const meta = document.createElement("div");
                meta.className = "executor-card__changelog-meta";

                const version = document.createElement("span");
                version.className = "executor-card__changelog-version";
                version.textContent = String(item.version || "Update");
                meta.appendChild(version);

                const formattedDate = formatExecutorChangelogDate(item);
                if (formattedDate) {
                    const date = document.createElement("span");
                    date.className = "executor-card__changelog-date";
                    date.textContent = formattedDate;
                    meta.appendChild(date);
                }

                entry.appendChild(meta);

                const bodyText = String(item.changelog || "").trim();
                if (bodyText) {
                    const body = document.createElement("p");
                    body.className = "executor-card__changelog-body";
                    body.textContent = bodyText;
                    entry.appendChild(body);
                }

                list.appendChild(entry);
            });

            section.append(heading, list);
            return section;
        }

        async function loadExecutorChangelogCache() {
            try {
                const response = await fetch(
                    \`\${executorChangelogCacheUrl}?t=\${Date.now()}\`
                );
                if (!response.ok) {
                    throw new Error(
                        \`\${response.status} \${response.statusText || "Error"}\`
                    );
                }
                const payload = await response.json();
                executorChangelogCacheFetchedAt =
                    payload.fetchedAt || payload.updatedAt || null;
                executorChangelogCache = payload.data ?? payload;
            } catch (error) {
                executorChangelogCache = null;
                executorChangelogCacheFetchedAt = null;
                console.warn("Unable to load executor changelogs:", error);
            }
        }
`,
"function getExecutorChangelogRecord(executor) {"
);

replaceOnce(
`            details.appendChild(stats);

            card.append(summary);
`,
`            details.appendChild(stats);

            const changelogSection = createExecutorChangelogSection(executor);
            if (changelogSection) {
                details.appendChild(changelogSection);
            }

            card.append(summary);
`,
"const changelogSection = createExecutorChangelogSection(executor);"
);

replaceOnce(
`                executorCache = Array.isArray(data) ? data : [];
                renderExecutorHashPicker();
`,
`                executorCache = Array.isArray(data) ? data : [];
                await loadExecutorChangelogCache();
                renderExecutorHashPicker();
`,
"await loadExecutorChangelogCache();"
);

await fs.writeFile(filePath, source, "utf8");
console.log("WEAO changelog UI support applied.");
