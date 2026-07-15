import fs from "node:fs/promises";
import path from "node:path";

const HEADERS = { "User-Agent": "WEAO-3PService" };

const VERSION_ENDPOINTS = {
    current: "https://weao.xyz/api/versions/current",
    future: "https://weao.xyz/api/versions/future",
    past: "https://weao.xyz/api/versions/past"
};

const EXECUTOR_ENDPOINT = "https://weao.xyz/api/status/exploits";
const CHANGELOG_ENDPOINT = "https://weao.xyz/api/status/exploits/changelogs";
const CHANGELOG_REFRESH_INTERVAL = 6 * 60 * 60 * 1000;

async function fetchJson(url) {
    const response = await fetch(url, { headers: HEADERS });
    const text = await response.text();

    if (!response.ok) {
        throw new Error(
            `Request failed ${response.status} ${response.statusText}: ${text || "no body"}`
        );
    }

    try {
        return text ? JSON.parse(text) : null;
    } catch {
        throw new Error(`Invalid JSON returned by ${url}`);
    }
}

async function fetchOptionalJson(url) {
    try {
        const response = await fetch(url, { headers: HEADERS });
        const text = await response.text();
        let data = null;

        try {
            data = text ? JSON.parse(text) : null;
        } catch {}

        return {
            ok: response.ok,
            status: response.status,
            data
        };
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

    await fs.writeFile(
        filePath,
        `${JSON.stringify({ fetchedAt, data }, null, 2)}\n`,
        "utf8"
    );
    console.log(`WEAO cache refreshed: ${path.basename(filePath)}`);
    return true;
}

function getExecutorKey(executor) {
    return String(
        executor?.trackerId || executor?._id || executor?.title || ""
    ).trim();
}

function createEmptyChangelogResponse(executor) {
    return {
        trackerId: executor?.trackerId || "",
        name: String(executor?.title || "").trim().toLowerCase(),
        displayName: executor?.title || "",
        changelogs: [],
        count: 0
    };
}

function isValidChangelogResponse(value) {
    return Boolean(
        value &&
        typeof value === "object" &&
        Array.isArray(value.changelogs)
    );
}

function shouldReuseEntry(previousEntry, executor, forceRefresh) {
    return Boolean(
        !forceRefresh &&
        previousEntry &&
        previousEntry.version === (executor?.version ?? null) &&
        previousEntry.updatedDate === (executor?.updatedDate ?? null) &&
        isValidChangelogResponse(previousEntry.changelogs)
    );
}

async function fetchExecutorChangelog(executor) {
    const identifiers = [executor?.trackerId, executor?.title]
        .filter((value) => typeof value === "string" && value.trim());

    for (const identifier of identifiers) {
        const url = `${CHANGELOG_ENDPOINT}/${encodeURIComponent(identifier.trim())}`;
        const result = await fetchOptionalJson(url);

        if (result.status === 429) {
            return {
                rateLimited: true,
                data: null
            };
        }

        if (result.ok && isValidChangelogResponse(result.data)) {
            return {
                rateLimited: false,
                data: result.data
            };
        }

        if (result.status !== 404) {
            break;
        }
    }

    return {
        rateLimited: false,
        data: null
    };
}

async function fetchExecutorChangelogs(executors, previousPayload) {
    const previousData = previousPayload?.data;
    const previousEntries = previousData?.entries &&
        typeof previousData.entries === "object"
        ? previousData.entries
        : {};
    const previousFetchedAt = Date.parse(previousPayload?.fetchedAt || "");
    const forceRefresh =
        !Number.isFinite(previousFetchedAt) ||
        Date.now() - previousFetchedAt >= CHANGELOG_REFRESH_INTERVAL;
    const entries = {};
    let rateLimited = false;

    for (const executor of executors) {
        const key = getExecutorKey(executor);
        if (!key) {
            continue;
        }

        const previousEntry = previousEntries[key];
        if (shouldReuseEntry(previousEntry, executor, forceRefresh)) {
            entries[key] = previousEntry;
            continue;
        }

        let response = null;
        if (!rateLimited) {
            const result = await fetchExecutorChangelog(executor);
            rateLimited = result.rateLimited;
            response = result.data;
        }

        entries[key] = {
            title: executor?.title || "",
            trackerId: executor?.trackerId || "",
            _id: executor?._id || "",
            version: executor?.version ?? null,
            updatedDate: executor?.updatedDate ?? null,
            changelogs:
                response ||
                previousEntry?.changelogs ||
                createEmptyChangelogResponse(executor)
        };

        if (!rateLimited) {
            await new Promise((resolve) => setTimeout(resolve, 125));
        }
    }

    if (rateLimited) {
        console.warn("WEAO changelog refresh was rate limited; cached entries were preserved.");
    }

    return {
        mode: "per-exploit",
        endpointPattern: `${CHANGELOG_ENDPOINT}/[trackerId]`,
        identifier: "trackerId-or-title",
        entries
    };
}

async function main() {
    const destination = path.join(process.cwd(), ".well-known", "weao");
    await fs.mkdir(destination, { recursive: true });

    const fetchedAt = new Date().toISOString();
    const versionsPath = path.join(destination, "versions.json");
    const executorsPath = path.join(destination, "executors.json");
    const changelogsPath = path.join(destination, "executor-changelogs.json");

    const versions = {};
    for (const [key, url] of Object.entries(VERSION_ENDPOINTS)) {
        versions[key] = await fetchJson(url);
    }

    const executorResponse = await fetchJson(EXECUTOR_ENDPOINT);
    const executors = Array.isArray(executorResponse)
        ? executorResponse
        : Array.isArray(executorResponse?.data)
            ? executorResponse.data
            : [];
    const previousChangelogs = await readExistingPayload(changelogsPath);
    const changelogs = await fetchExecutorChangelogs(
        executors,
        previousChangelogs
    );

    const versionsChanged = await writeCacheFile(
        versionsPath,
        versions,
        fetchedAt
    );
    const executorsChanged = await writeCacheFile(
        executorsPath,
        executorResponse,
        fetchedAt
    );
    const changelogsChanged = await writeCacheFile(
        changelogsPath,
        changelogs,
        fetchedAt
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
