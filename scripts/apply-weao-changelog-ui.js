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

        .executor-card__changelog-title {
            margin: 0;
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: var(--tx);
        }

        .executor-card__changelog-list {
            display: grid;
            gap: 8px;
        }

        .executor-card__changelog-entry {
            display: grid;
            gap: 5px;
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
            font-size: 12px;
            font-weight: 800;
            color: var(--ac);
        }

        .executor-card__changelog-date {
            font-size: 11px;
            color: var(--mu);
        }

        .executor-card__changelog-body {
            margin: 0;
            color: rgba(231, 233, 238, 0.84);
            font-size: 13px;
            line-height: 1.55;
            white-space: pre-wrap;
            overflow-wrap: anywhere;
        }
`,
".executor-card__changelog {"
);

insertAfter(
`        const executorCacheUrl = \`${"${weaoCacheBase}"}/executors.json\`;
`,
`        const executorChangelogCacheUrl = \`${"${weaoCacheBase}"}/executor-changelogs.json\`;
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
        function getExecutorIdentityValues(executor) {
            const slug = typeof executor?.slug === "string" ?
                executor.slug :
                executor?.slug?.slug || executor?.slug?.name || "";
            return [
                executor?.trackerId,
                executor?._id,
                executor?.title,
                slug
            ]
                .filter((value) => typeof value === "string" && value.trim())
                .flatMap((value) => {
                    const trimmed = value.trim();
                    const normalized = trimmed.toLowerCase();
                    return normalized === trimmed ? [trimmed] : [trimmed, normalized];
                });
        }

        function matchesExecutorIdentity(value, executor) {
            if (!value || typeof value !== "object") {
                return false;
            }

            const candidateValues = [
                value.trackerId,
                value._id,
                value.exploitId,
                value.exploit,
                value.executor,
                value.title,
                value.name,
                value.slug
            ]
                .filter((entry) => typeof entry === "string" && entry.trim())
                .map((entry) => entry.trim().toLowerCase());
            const identities = new Set(
                getExecutorIdentityValues(executor).map((entry) => entry.toLowerCase())
            );
            return candidateValues.some((entry) => identities.has(entry));
        }

        function getDirectChangelogValue(record) {
            if (!record || typeof record !== "object") {
                return record;
            }

            for (const key of [
                "changelogs",
                "changelog",
                "history",
                "logs",
                "updates",
                "releases",
                "entries",
                "items",
                "data"
            ]) {
                if (record[key] !== undefined && record[key] !== record) {
                    return record[key];
                }
            }

            return record;
        }

        function findExecutorChangelogPayload(executor) {
            const cache = executorChangelogCache;
            if (!cache || typeof cache !== "object") {
                return null;
            }

            const identities = getExecutorIdentityValues(executor);
            if (cache.mode === "per-exploit") {
                const entries = cache.entries && typeof cache.entries === "object" ?
                    cache.entries :
                    {};
                const entryKeys = Object.keys(entries);
                for (const identity of identities) {
                    const exact = entries[identity];
                    if (exact) {
                        return getDirectChangelogValue(exact);
                    }
                    const matchedKey = entryKeys.find(
                        (key) => key.toLowerCase() === identity.toLowerCase()
                    );
                    if (matchedKey) {
                        return getDirectChangelogValue(entries[matchedKey]);
                    }
                }
                return null;
            }

            const root = cache.mode === "all" ? cache.payload : cache;
            if (!root) {
                return null;
            }

            if (root && typeof root === "object" && !Array.isArray(root)) {
                const rootKeys = Object.keys(root);
                for (const identity of identities) {
                    if (root[identity] !== undefined) {
                        return getDirectChangelogValue(root[identity]);
                    }
                    const matchedKey = rootKeys.find(
                        (key) => key.toLowerCase() === identity.toLowerCase()
                    );
                    if (matchedKey) {
                        return getDirectChangelogValue(root[matchedKey]);
                    }
                }
            }

            const collections = [
                root?.data,
                root?.changelogs,
                root?.history,
                root?.logs,
                root?.updates,
                root?.releases,
                root?.entries,
                root?.items,
                root
            ];

            for (const collection of collections) {
                if (!Array.isArray(collection)) {
                    continue;
                }
                const matches = collection.filter((entry) =>
                    matchesExecutorIdentity(entry, executor)
                );
                if (matches.length) {
                    return matches.flatMap((entry) => {
                        const value = getDirectChangelogValue(entry);
                        return Array.isArray(value) ? value : [value];
                    });
                }
            }

            return null;
        }

        function normalizeExecutorChangelogItems(value, depth = 0) {
            if (value === null || value === undefined || depth > 5) {
                return [];
            }

            if (Array.isArray(value)) {
                return value.flatMap((entry) =>
                    normalizeExecutorChangelogItems(entry, depth + 1)
                );
            }

            if (typeof value === "string" || typeof value === "number") {
                const body = String(value).trim();
                return body ? [{ body }] : [];
            }

            if (typeof value !== "object") {
                return [];
            }

            const hasEntryMetadata = [
                "version",
                "title",
                "name",
                "date",
                "createdAt",
                "updatedAt",
                "timestamp",
                "body",
                "description",
                "content",
                "message",
                "notes",
                "changes"
            ].some((key) => value[key] !== undefined);

            if (hasEntryMetadata) {
                return [value];
            }

            for (const key of [
                "changelogs",
                "changelog",
                "history",
                "logs",
                "updates",
                "releases",
                "entries",
                "items",
                "data"
            ]) {
                if (value[key] !== undefined && value[key] !== value) {
                    const nested = normalizeExecutorChangelogItems(value[key], depth + 1);
                    if (nested.length) {
                        return nested;
                    }
                }
            }

            return Object.values(value).flatMap((entry) =>
                normalizeExecutorChangelogItems(entry, depth + 1)
            );
        }

        function stringifyChangelogValue(value) {
            if (value === null || value === undefined) {
                return "";
            }
            if (Array.isArray(value)) {
                return value
                    .map((entry) => stringifyChangelogValue(entry))
                    .filter(Boolean)
                    .join("\n");
            }
            if (typeof value === "object") {
                return Object.values(value)
                    .map((entry) => stringifyChangelogValue(entry))
                    .filter(Boolean)
                    .join("\n");
            }
            return String(value).trim();
        }

        function createExecutorChangelogSection(executor) {
            const payload = findExecutorChangelogPayload(executor);
            const items = normalizeExecutorChangelogItems(payload)
                .map((entry) => {
                    const objectEntry = entry && typeof entry === "object" ? entry : {};
                    const version = String(
                        objectEntry.version ||
                        objectEntry.release ||
                        objectEntry.title ||
                        objectEntry.name ||
                        "Update"
                    ).trim();
                    const date = String(
                        objectEntry.date ||
                        objectEntry.createdAt ||
                        objectEntry.updatedAt ||
                        objectEntry.updatedDate ||
                        objectEntry.timestamp ||
                        ""
                    ).trim();
                    const body = stringifyChangelogValue(
                        objectEntry.body ??
                        objectEntry.description ??
                        objectEntry.content ??
                        objectEntry.message ??
                        objectEntry.notes ??
                        objectEntry.changes ??
                        objectEntry.changelog ??
                        objectEntry.bodyText ??
                        ""
                    );
                    return { version, date, body };
                })
                .filter((entry) => entry.body || entry.version !== "Update")
                .slice(0, 8);

            if (!items.length) {
                return null;
            }

            const section = document.createElement("section");
            section.className = "executor-card__changelog";

            const heading = document.createElement("h4");
            heading.className = "executor-card__changelog-title";
            heading.textContent = "Changelog";

            const list = document.createElement("div");
            list.className = "executor-card__changelog-list";

            items.forEach((item) => {
                const entry = document.createElement("article");
                entry.className = "executor-card__changelog-entry";

                const meta = document.createElement("div");
                meta.className = "executor-card__changelog-meta";

                const version = document.createElement("span");
                version.className = "executor-card__changelog-version";
                version.textContent = item.version;
                meta.appendChild(version);

                if (item.date) {
                    const date = document.createElement("span");
                    date.className = "executor-card__changelog-date";
                    date.textContent = item.date;
                    meta.appendChild(date);
                }

                entry.appendChild(meta);

                if (item.body) {
                    const body = document.createElement("p");
                    body.className = "executor-card__changelog-body";
                    body.textContent = item.body;
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
                    \`${"${executorChangelogCacheUrl}"}?t=${"${Date.now()}"}\`
                );
                if (!response.ok) {
                    throw new Error(\`${"${response.status}"} ${"${response.statusText || \"Error\"}"}\`);
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
"function getExecutorIdentityValues(executor) {"
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
