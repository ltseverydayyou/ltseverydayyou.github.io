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

async function main() {
    const destDir = path.join(process.cwd(), ".well-known", "weao");
    await fs.mkdir(destDir, { recursive: true });

    const fetchedAt = new Date().toISOString();

    const versions = {};
    for (const [key, url] of Object.entries(VERSION_ENDPOINTS)) {
        versions[key] = await fetchJson(url);
    }

    const executors = await fetchJson(EXECUTOR_ENDPOINT);

    await fs.writeFile(
        path.join(destDir, "versions.json"),
        JSON.stringify({ fetchedAt, data: versions }, null, 2),
        "utf8"
    );

    await fs.writeFile(
        path.join(destDir, "executors.json"),
        JSON.stringify({ fetchedAt, data: executors }, null, 2),
        "utf8"
    );

    console.log("WEAO cache refreshed at", fetchedAt);
}

main().catch((error) => {
    console.error("Failed to refresh WEAO cache:", error);
    process.exitCode = 1;
});
