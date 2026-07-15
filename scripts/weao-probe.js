import fs from "node:fs";

const headers = { "User-Agent": "WEAO-3PService" };

async function read(url, options = {}) {
    try {
        const response = await fetch(url, options);
        return {
            url,
            status: response.status,
            contentType: response.headers.get("content-type") || "",
            text: await response.text()
        };
    } catch (error) {
        return { url, status: 0, contentType: "", text: String(error) };
    }
}

function decodeHtml(value) {
    return value
        .replace(/\\u002f/gi, "/")
        .replace(/\\\//g, "/")
        .replace(/&quot;|&#34;/gi, '"')
        .replace(/&#39;|&apos;/gi, "'")
        .replace(/&lt;/gi, "<")
        .replace(/&gt;/gi, ">")
        .replace(/&amp;/gi, "&")
        .replace(/&#x2f;/gi, "/")
        .replace(/&#x3a;/gi, ":")
        .replace(/&#x3f;/gi, "?")
        .replace(/&#x3d;/gi, "=")
        .replace(/&#x26;/gi, "&");
}

function plainText(value) {
    return decodeHtml(value)
        .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
        .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
        .replace(/<[^>]+>/g, " ")
        .replace(/\s+/g, " ")
        .trim();
}

const docs = await read("https://docs.weao.xyz/weao-api-reference/exploits");
const marker = 'id="retrieving-exploit-changelogs"';
const start = docs.text.indexOf(marker);
const nextHeading = start === -1 ? -1 : docs.text.indexOf("<h2", start + marker.length);
const rawSection = start === -1
    ? ""
    : docs.text.slice(start, nextHeading === -1 ? start + 120000 : nextHeading);
const decodedSection = decodeHtml(rawSection);
const routes = new Set();

for (const match of decodedSection.matchAll(/https?:\/\/(?:www\.)?weao\.xyz\/api\/[A-Za-z0-9_~:?#[\]@!$&'()*+,;=%./{}-]+/gi)) {
    routes.add(match[0].replace(/[),.;]+$/, ""));
}
for (const match of decodedSection.matchAll(/\/api\/[A-Za-z0-9_~:?#[\]@!$&'()*+,;=%./{}-]+/gi)) {
    routes.add(match[0].replace(/[),.;]+$/, ""));
}

const statuses = await read("https://weao.xyz/api/status/exploits", { headers });
let entries = [];
try {
    const parsed = JSON.parse(statuses.text);
    entries = Array.isArray(parsed) ? parsed : Array.isArray(parsed?.data) ? parsed.data : [];
} catch {}

const sample = entries.find((entry) => entry?.title) || {};
const identifiers = [sample.title, sample._id, sample.trackerId]
    .filter((value) => typeof value === "string" && value.trim());
const candidates = new Set();

for (const route of routes) {
    candidates.add(/^https?:\/\//i.test(route) ? route : `https://weao.xyz${route}`);
}

for (const identifier of identifiers) {
    const encoded = encodeURIComponent(identifier);
    for (const template of [
        `/api/status/exploits/${encoded}/changelogs`,
        `/api/status/exploits/${encoded}/changelog`,
        `/api/status/exploits/changelogs/${encoded}`,
        `/api/status/exploits/changelog/${encoded}`,
        `/api/changelogs/exploits/${encoded}`,
        `/api/changelog/exploits/${encoded}`,
        `/api/exploits/${encoded}/changelogs`,
        `/api/exploits/${encoded}/changelog`,
        `/api/changelogs/${encoded}`,
        `/api/changelog/${encoded}`,
        `/api/status/changelogs/${encoded}`,
        `/api/status/changelog/${encoded}`
    ]) {
        candidates.add(`https://weao.xyz${template}`);
    }
}

const responses = [];
for (const url of candidates) {
    if (/[{[:](?:id|tracker|exploit|name|slug)[}\]]/i.test(url)) {
        continue;
    }
    const result = await read(url, { headers });
    if (result.status !== 404) {
        responses.push({
            url,
            status: result.status,
            contentType: result.contentType,
            body: result.text.slice(0, 12000)
        });
    }
}

const output = {
    generatedAt: new Date().toISOString(),
    docs: {
        status: docs.status,
        contentType: docs.contentType,
        length: docs.text.length,
        sectionText: plainText(rawSection),
        routes: [...routes],
        rawSection
    },
    statuses: {
        status: statuses.status,
        count: entries.length
    },
    sample: {
        title: sample.title,
        id: sample._id,
        trackerId: sample.trackerId
    },
    responses
};

fs.writeFileSync("probe-output.json", `${JSON.stringify(output, null, 2)}\n`, "utf8");
console.log(`Stored ${responses.length} non-404 response candidates.`);
