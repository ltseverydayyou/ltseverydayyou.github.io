import fs from "node:fs/promises";
import path from "node:path";

const HEADERS = { "User-Agent": "WEAO-3PService" };

const VERSION_ENDPOINTS = {
    current: "https://weao.xyz/api/versions/current",
    future: "https://weao.xyz/api/versions/future",
    past: "https://weao.xyz/api/versions/past"
};

const EXECUTOR_ENDPOINT = "https://weao.xyz/api/status/exploits";
const CHANGELOG_ALL_ENDPOINTS = [
    "https://weao.xyz/api/status/exploits/changelogs",
    "https://weao.xyz/api/changelogs/exploits",
    "https://weao.xyz/api/exploits/changelogs"
];
const CHANGELOG_PATTERNS = [
    "https://weao.xyz/api/status/exploits/{exploit}/changelogs",
    "https://weao.xyz/api/status/exploits/{exploit}/changelog",
    "https://weao.xyz/api/status/exploits/changelogs/{exploit}",
    "https://weao.xyz/api/status/exploits/changelog/{exploit}",
    "https://weao.xyz/api/changelogs/exploits/{exploit}",
    "https://weao.xyz/api/changelog/exploits/{exploit}",
    "https://weao.xyz/api/exploits/{exploit}/changelogs",
    "https://weao.xyz/api/exploits/{exploit}/changelog",
    "https://weao.xyz/api/changelogs/{exploit}",
    "https://weao.xyz/api/changelog/{exploit}"
];
const CHANGELOG_IDENTIFIERS = ["title", "slug", "trackerId", "_id"];
const CHANGELOG_REFRESH_INTERVAL = 6 * 60 * 60 * 1000;

async function fetchJson(url) {
    const response = await fetch(url, { headers: HEADERS });
    if (!response.ok) {
        const text = await response.text().catch(() => "");
        throw new Error(`Request failed ${response.status} ${response.statusText}: ${text || "no body"}`);
    }
    return response.json();
}

async function fetchOptionalJson(url) {
    try {
        const response = await fetch(url, { headers: HEADERS });
        const text = await response.text();
        if (!response.ok) {
            return {
                ok: false,
                status: response.status,
                data: null
            };
        }

        try {
            return {
                ok: true,
                status: response.status,
                data: text ? JSON.parse(text) : null
            };
        } catch {
            return {
                ok: false,
                status: response.status,
                data: null
            };
        }
    } catch {
        return {
            ok: false,
            status: 0,
            data: null
        };
    }
}

async function readExistingPayload(filePath) {
    try {
        const raw = await fs.readFile(filePath, "utf8");
        return JSON.parse(raw);
    } catch (error) {
        if (error?.code === "ENOENT") {
            return null;
        }
        throw error;
    }
}

function normalizeForCompare(value) {
    if (Array.isArray(value)) {
        return value.map(normalizeForCompare);
    }
    if (value && typeof value === "object") {
        return Object.fromEntries(
            Object.keys(value)
                .sort()
                .map((key) => [key, normalizeForCompare(value[key])])
        );
    }
    return value;
}

async function writeCacheFile(filePath, data, fetchedAt) {
    const previousPayload = await readExistingPayload(filePath);
    const previousData = previousPayload?.data;

    if (
        previousData !== undefined &&
        JSON.stringify(normalizeForCompare(previousData)) ===
            JSON.stringify(normalizeForCompare(data))
    ) {
        console.log(`WEAO cache unchanged: ${path.basename(filePath)}`);
        return false;
    }

    const payload = { fetchedAt, data };
    await fs.writeFile(filePath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
    console.log(`WEAO cache refreshed: ${path.basename(filePath)}`);
    return true;
}

function isErrorPayload(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        return false;
    }

    const keys = Object.keys(value).map((key) => key.toLowerCase());
    return (
        keys.includes("error") ||
        keys.includes("errors") ||
        (keys.includes("message") && keys.length <= 3 && !keys.includes("changes"))
    );
}

function isUsableChangelogPayload(value) {
    if (value === null || value === undefined || isErrorPayload(value)) {
        return false;
    }

    if (Array.isArray(value)) {
        return true;
    }

    if (typeof value !== "object") {
        return typeof value === "string" && value.trim().length > 0;
    }

    const keys = Object.keys(value).map((key) => key.toLowerCase());
    const changelogKeys = new Set([
        "changelog",
        "changelogs",
        "changes",
        "history",
        "logs",
        "updates",
        "entries",
        "items",
        "releases",
        "data"
    ]);

    if (keys.some((key) => changelogKeys.has(key))) {
        return true;
    }

    return Object.values(value).some((entry) => Array.isArray(entry));
}

function slugify(value) {
    return String(value || "")
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "");
}

function getIdentifierValue(executor, identifier) {
    if (!executor || typeof executor !== "object") {
        return "";
    }

    if (identifier === "slug") {
        if (typeof executor.slug === "string") {
            return executor.slug.trim();
        }
        if (typeof executor.slug?.slug === "string") {
            return executor.slug.slug.trim();
        }
        if (typeof executor.slug?.name === "string") {
            return executor.slug.name.trim();
        }
        return slugify(executor.title);
    }

    return String(executor[identifier] || "").trim();
}

function buildChangelogUrl(pattern, executor, identifier) {
    const value = getIdentifierValue(executor, identifier);
    if (!value) {
        return "";
    }
    return pattern.replace("{exploit}", encodeURIComponent(value));
}

function getExecutorCacheKey(executor) {
    return String(executor?.trackerId || executor?._id || executor?.title || "").trim();
}

function shouldReuseChangelog(previousEntry, executor, forceRefresh) {
    return (
        !forceRefresh &&
        previousEntry &&
        previousEntry.version === (executor.version ?? null) &&
        previousEntry.updatedDate === (executor.updatedDate ?? null) &&
        previousEntry.changelogs !== undefined
    );
}

async function discoverAllChangelogEndpoint(previousData) {
    const endpoints = [];
    if (previousData?.mode === "all" && typeof previousData.endpoint === "string") {
        endpoints.push(previousData.endpoint);
    }
    endpoints.push(...CHANGELOG_ALL_ENDPOINTS);

    for (const endpoint of [...new Set(endpoints)]) {
        const result = await fetchOptionalJson(endpoint);
        if (result.ok && isUsableChangelogPayload(result.data)) {
            return {
                endpoint,
                payload: result.data
            };
        }
    }

    return null;
}

async function discoverPerExecutorChangelogRoute(executors, previousData) {
    const sample = executors.find((entry) => entry?.title);
    if (!sample) {
        return null;
    }

    const candidates = [];
    if (
        previousData?.mode === "per-exploit" &&
        typeof previousData.endpointPattern === "string" &&
        typeof previousData.identifier === "string"
    ) {
        candidates.push({
            endpointPattern: previousData.endpointPattern,
            identifier: previousData.identifier
        });
    }

    for (const endpointPattern of CHANGELOG_PATTERNS) {
        for (const identifier of CHANGELOG_IDENTIFIERS) {
            candidates.push({ endpointPattern, identifier });
        }
    }

    const seen = new Set();
    for (const candidate of candidates) {
        const signature = `${candidate.endpointPattern}|${candidate.identifier}`;
        if (seen.has(signature)) {
            continue;
        }
        seen.add(signature);

        const url = buildChangelogUrl(candidate.endpointPattern, sample, candidate.identifier);
        if (!url) {
            continue;
        }

        const result = await fetchOptionalJson(url);
        if (result.ok && isUsableChangelogPayload(result.data)) {
            return candidate;
        }
    }

    return null;
}

async function fetchPerExecutorChangelogs(executors, route, previousData, forceRefresh) {
    const previousEntries = previousData?.entries && typeof previousData.entries === "object"
        ? previousData.entries
        : {};
    const entries = {};

    for (const executor of executors) {
        const key = getExecutorCacheKey(executor);
        if (!key) {
            continue;
        }

        const previousEntry = previousEntries[key];
        if (shouldReuseChangelog(previousEntry, executor, forceRefresh)) {
            entries[key] = previousEntry;
            continue;
        }

        const url = buildChangelogUrl(route.endpointPattern, executor, route.identifier);
        const result = url ? await fetchOptionalJson(url) : { ok: false, data: null };

        if (result.ok && isUsableChangelogPayload(result.data)) {
            entries[key] = {
                title: executor.title || "",
                trackerId: executor.trackerId || "",
                _id: executor._id || "",
                version: executor.version ?? null,
                updatedDate: executor.updatedDate ?? null,
                changelogs: result.data
            };
        } else if (previousEntry) {
            entries[key] = previousEntry;
        } else {
            entries[key] = {
                title: executor.title || "",
                trackerId: executor.trackerId || "",
                _id: executor._id || "",
                version: executor.version ?? null,
                updatedDate: executor.updatedDate ?? null,
                changelogs: []
            };
        }

        await new Promise((resolve) => setTimeout(resolve, 100));
    }

    return {
        mode: "per-exploit",
        endpointPattern: route.endpointPattern,
        identifier: route.identifier,
        entries
    };
}

async function fetchExecutorChangelogs(executors, previousPayload) {
    const previousData = previousPayload?.data;
    const previousFetchedAt = Date.parse(previousPayload?.fetchedAt || "");
    const forceRefresh =
        !Number.isFinite(previousFetchedAt) ||
        Date.now() - previousFetchedAt >= CHANGELOG_REFRESH_INTERVAL;

    const allChangelogs = await discoverAllChangelogEndpoint(previousData);
    if (allChangelogs) {
        return {
            mode: "all",
            endpoint: allChangelogs.endpoint,
            payload: allChangelogs.payload
        };
    }

    const route = await discoverPerExecutorChangelogRoute(executors, previousData);
    if (route) {
        return fetchPerExecutorChangelogs(
            executors,
            route,
            previousData,
            forceRefresh
        );
    }

    console.warn("No compatible WEAO changelog endpoint was found.");
    return previousData || {
        mode: "unavailable",
        entries: {}
    };
}

async function main() {
    const destDir = path.join(process.cwd(), ".well-known", "weao");
    await fs.mkdir(destDir, { recursive: true });

    const fetchedAt = new Date().toISOString();
    const versionsPath = path.join(destDir, "versions.json");
    const executorsPath = path.join(destDir, "executors.json");
    const changelogsPath = path.join(destDir, "executor-changelogs.json");

    const versions = {};
    for (const [key, url] of Object.entries(VERSION_ENDPOINTS)) {
        versions[key] = await fetchJson(url);
    }

    const executors = await fetchJson(EXECUTOR_ENDPOINT);
    const previousChangelogs = await readExistingPayload(changelogsPath);
    const changelogs = await fetchExecutorChangelogs(
        Array.isArray(executors) ? executors : [],
        previousChangelogs
    );

    const versionsChanged = await writeCacheFile(versionsPath, versions, fetchedAt);
    const executorsChanged = await writeCacheFile(executorsPath, executors, fetchedAt);
    const changelogsChanged = await writeCacheFile(changelogsPath, changelogs, fetchedAt);

    if (!versionsChanged && !executorsChanged && !changelogsChanged) {
        console.log("WEAO cache already up to date.");
        return;
    }

    console.log("WEAO cache checked at", fetchedAt);
}

main().catch((error) => {
    console.error("Failed to refresh WEAO cache:", error);
    process.exitCode = 1;
});
