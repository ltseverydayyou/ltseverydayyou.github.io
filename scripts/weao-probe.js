import fs from "node:fs";

const headers = { "User-Agent": "WEAO-3PService" };
const domains = ["https://weao.xyz", "https://whatexpsare.online", "https://weao.gg"];

async function readJson(url) {
    try {
        const response = await fetch(url, { headers });
        const text = await response.text();
        let data = null;
        try {
            data = JSON.parse(text);
        } catch {}
        return {
            url,
            status: response.status,
            contentType: response.headers.get("content-type") || "",
            data,
            body: data ? undefined : text.slice(0, 1000)
        };
    } catch (error) {
        return { url, status: 0, data: null, body: String(error) };
    }
}

function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

const statusResult = await readJson(`${domains[0]}/api/status/exploits`);
const executors = Array.isArray(statusResult.data)
    ? statusResult.data
    : Array.isArray(statusResult.data?.data)
        ? statusResult.data.data
        : [];
const attempts = [];
const samples = [];

for (const executor of executors) {
    const identifier = executor?.trackerId || executor?.title;
    if (!identifier) {
        continue;
    }

    let accepted = null;
    for (const domain of domains) {
        const result = await readJson(
            `${domain}/api/status/exploits/changelogs/${encodeURIComponent(identifier)}`
        );
        attempts.push({
            title: executor.title,
            trackerId: executor.trackerId,
            url: result.url,
            status: result.status,
            count: result.data?.count,
            changelogCount: Array.isArray(result.data?.changelogs)
                ? result.data.changelogs.length
                : null,
            body: result.body
        });
        if (result.status === 200 && result.data && typeof result.data === "object") {
            accepted = result.data;
            break;
        }
        await sleep(300);
    }

    if (accepted && (accepted.count > 0 || accepted.changelogs?.length > 0)) {
        samples.push({ executor, response: accepted });
        if (samples.length >= 3) {
            break;
        }
    }

    await sleep(400);
}

const output = {
    generatedAt: new Date().toISOString(),
    status: {
        url: statusResult.url,
        status: statusResult.status,
        executorCount: executors.length
    },
    samples,
    attempts
};

fs.writeFileSync("probe-output.json", `${JSON.stringify(output, null, 2)}\n`, "utf8");
console.log(`Stored ${samples.length} non-empty changelog samples.`);
