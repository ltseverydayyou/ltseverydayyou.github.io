import fs from "node:fs/promises";
import path from "node:path";

const HEADERS = { "User-Agent": "WEAO-3PService" };
const VERSION_ENDPOINTS = {
    current: "https://weao.xyz/api/versions/current",
    future: "https://weao.xyz/api/versions/future",
    past: "https://weao.xyz/api/versions/past"
};
const EXECUTOR_ENDPOINT = "https://weao.xyz/api/status/exploits";
const CHANGELOG_DOMAINS = [
    "https://weao.xyz",
    "https://whatexpsare.online",
    "https://weao.gg"
];
const CHANGELOG_REFRESH_INTERVAL = 6 * 60 * 60 * 1000;
const REQUEST_DELAY = 150;

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
            return { ok: false, status: response.status, data: null };
        }
        try {
            return {
                ok: true,
                status: response.status,
                data: text ? JSON.parse(text) : null
            };
        } catch {
            return { ok: false, status: response.status, data: null };
        }
    } catch {
        return { ok: false, status: 0, data: null };
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

async function writeCacheFile(filePath, data, fetchedAt, refreshTimestamp = false) {
    const previousPayload = await readExistingPayload(filePath);
    const previousData = previousPayload?.data;
    const unchanged =
        previousData !== undefined &&
        JSON.stringify(normalizeForCompare(previousData)) ===
            JSON.stringify(normalizeForCompare(data));

    if (unchanged && !refreshTimestamp) {
        console.log(`WEAO cache unchanged: ${path.basename(filePath)}`);
        return false;
    }

    const payload = { fetchedAt, data };
    await fs.writeFile(filePath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
    console.log(`WEAO cache refreshed: ${path.basename(filePath)}`);
    return true;
}

function sleep(milliseconds) {
    return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function getExecutorCacheKey(executor) {
    return String(executor?.trackerId || executor?._id || executor?.title || "").trim();
}

function getChangelogIdentifier(executor) {
    return String(executor?.trackerId || executor?.title || "").trim();
}

function isValidChangelogPayload(value) {
    return (
        value &&
        typeof value === "object" &&
        !Array.isArray(value) &&
        Array.isArray(value.changelogs) &&
        typeof value.count === "number"
    );
}

function shouldRefreshAllChangelogs(previousPayload) {
    const fetchedAt = Date.parse(previousPayload?.fetchedAt || "");
    return (
        !Number.isFinite(fetchedAt) ||
        Date.now() - fetchedAt >= CHANGELOG_REFRESH_INTERVAL
    );
}

function canReuseChangelog(previousEntry, executor, refreshAll) {
    return (
        !refreshAll &&
        previousEntry &&
        previousEntry.version === (executor.version ?? null) &&
        previousEntry.updatedDate === (executor.updatedDate ?? null) &&
        isValidChangelogPayload(previousEntry.response)
    );
}

async function fetchExecutorChangelog(executor, domainOffset) {
    const identifier = getChangelogIdentifier(executor);
    if (!identifier) {
        return null;
    }

    for (let index = 0; index < CHANGELOG_DOMAINS.length; index += 1) {
        const domain = CHANGELOG_DOMAINS[(domainOffset + index) % CHANGELOG_DOMAINS.length];
        const url = `${domain}/api/status/exploits/changelogs/${encodeURIComponent(identifier)}`;
        const result = await fetchOptionalJson(url);
        if (result.ok && isValidChangelogPayload(result.data)) {
            return result.data;
        }
    }

    return null;
}

async function fetchExecutorChangelogs(executors, previousPayload, refreshAll) {
    const previousEntries = previousPayload?.data?.entries;
    const existing = previousEntries && typeof previousEntries === "object"
        ? previousEntries
        : {};
    const entries = {};
    let requestIndex = 0;

    for (const executor of executors) {
        const key = getExecutorCacheKey(executor);
        if (!key) {
            continue;
        }

        const previousEntry = existing[key];
        if (canReuseChangelog(previousEntry, executor, refreshAll)) {
            entries[key] = previousEntry;
            continue;
        }

        const response = await fetchExecutorChangelog(executor, requestIndex);
        requestIndex += 1;

        if (response) {
            entries[key] = {
                title: executor.title || "",
                trackerId: executor.trackerId || "",
                _id: executor._id || "",
                version: executor.version ?? null,
                updatedDate: executor.updatedDate ?? null,
                response
            };
        } else if (previousEntry) {
            entries[key] = previousEntry;
            console.warn(`Using stale WEAO changelog cache for ${executor.title || key}.`);
        } else {
            console.warn(`No WEAO changelog data available for ${executor.title || key}.`);
        }

        await sleep(REQUEST_DELAY);
    }

    return {
        mode: "per-exploit",
        endpointPattern: "https://weao.xyz/api/status/exploits/changelogs/[trackerId]",
        entries
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
    const executorList = Array.isArray(executors) ? executors : [];
    const previousChangelogs = await readExistingPayload(changelogsPath);
    const refreshAllChangelogs = shouldRefreshAllChangelogs(previousChangelogs);
    const changelogs = await fetchExecutorChangelogs(
        executorList,
        previousChangelogs,
        refreshAllChangelogs
    );

    const versionsChanged = await writeCacheFile(versionsPath, versions, fetchedAt);
    const executorsChanged = await writeCacheFile(executorsPath, executors, fetchedAt);
    const changelogsChanged = await writeCacheFile(
        changelogsPath,
        changelogs,
        fetchedAt,
        refreshAllChangelogs
    );

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
