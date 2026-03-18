// Fetches WEAO API data with the required User-Agent header and writes
// cached copies into .well-known/weao for the static site to consume.
// Run locally or in CI to refresh data without browser CORS/User-Agent issues.

import fs from "node:fs/promises";
import path from "node:path";

const HEADERS = { "User-Agent": "WEAO-3PService" };

const VERSION_ENDPOINTS = {
    current: "https://weao.xyz/api/versions/current",
    future: "https://weao.xyz/api/versions/future",
    past: "https://weao.xyz/api/versions/past"
};

const EXECUTOR_ENDPOINT = "https://weao.xyz/api/status/exploits";

async function fetchJson(url) {
    const response = await fetch(url, { headers: HEADERS });
    if (!response.ok) {
        const text = await response.text().catch(() => "");
        throw new Error(`Request failed ${response.status} ${response.statusText}: ${text || "no body"}`);
    }
    return response.json();
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
        previousData &&
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

async function main() {
    const destDir = path.join(process.cwd(), ".well-known", "weao");
    await fs.mkdir(destDir, { recursive: true });

    const fetchedAt = new Date().toISOString();

    const versions = {};
    for (const [key, url] of Object.entries(VERSION_ENDPOINTS)) {
        versions[key] = await fetchJson(url);
    }

    const executors = await fetchJson(EXECUTOR_ENDPOINT);

    const versionsChanged = await writeCacheFile(
        path.join(destDir, "versions.json"),
        versions,
        fetchedAt
    );

    const executorsChanged = await writeCacheFile(
        path.join(destDir, "executors.json"),
        executors,
        fetchedAt
    );

    if (!versionsChanged && !executorsChanged) {
        console.log("WEAO cache already up to date.");
        return;
    }

    console.log("WEAO cache checked at", fetchedAt);
}

main().catch((error) => {
    console.error("Failed to refresh WEAO cache:", error);
    process.exitCode = 1;
});
