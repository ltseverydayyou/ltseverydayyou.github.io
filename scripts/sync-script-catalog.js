const fs = require("node:fs");
const path = require("node:path");

const catalogPath = path.join(__dirname, "catalog.json");
const writeChanges = process.argv.includes("--write");
const allowedStatuses = new Set(["supported", "maintenance", "retired"]);

function fail(message) {
  throw new Error(message);
}

function normalizeIds(value, field, scriptId) {
  if (value === undefined) return [];
  if (!Array.isArray(value)) fail(`${scriptId}.${field} must be an array`);

  const ids = value.map((id) => String(id).trim());
  if (ids.some((id) => !/^\d+$/.test(id))) {
    fail(`${scriptId}.${field} must contain decimal ID strings`);
  }
  return [...new Set(ids)].sort((a, b) => a.localeCompare(b));
}

function validateUrl(value, field, scriptId) {
  if (typeof value !== "string" || !value.trim()) {
    fail(`${scriptId}.${field} is required`);
  }
  const parsed = new URL(value);
  if (parsed.protocol !== "https:") fail(`${scriptId}.${field} must use HTTPS`);
}

async function resolveUniverseId(placeId) {
  const url = `https://apis.roblox.com/universes/v1/places/${placeId}/universe`;
  let lastError;

  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const payload = await response.json();
      const universeId = String(payload.universeId || "").trim();
      if (!/^\d+$/.test(universeId)) throw new Error("missing universeId");
      return universeId;
    } catch (error) {
      lastError = error;
      if (attempt < 3) await new Promise((resolve) => setTimeout(resolve, attempt * 750));
    }
  }

  fail(`unable to resolve place ${placeId}: ${lastError}`);
}

async function main() {
  const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
  if (catalog.schemaVersion !== 1) fail("schemaVersion must be 1");
  if (!Array.isArray(catalog.scripts)) fail("scripts must be an array");

  const seenIds = new Set();
  let changed = false;
  let gameLinked = 0;

  for (const script of catalog.scripts) {
    if (!script || typeof script !== "object" || Array.isArray(script)) {
      fail("every scripts entry must be an object");
    }
    if (typeof script.id !== "string" || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(script.id)) {
      fail("every script id must be a lowercase kebab-case string");
    }
    if (seenIds.has(script.id)) fail(`duplicate script id: ${script.id}`);
    seenIds.add(script.id);

    if (typeof script.name !== "string" || !script.name.trim()) fail(`${script.id}.name is required`);
    validateUrl(script.scriptUrl, "scriptUrl", script.id);
    if (script.imageUrl !== undefined) validateUrl(script.imageUrl, "imageUrl", script.id);
    if (!allowedStatuses.has(script.status)) fail(`${script.id}.status is invalid`);
    if (script.featured !== undefined && typeof script.featured !== "boolean") {
      fail(`${script.id}.featured must be a boolean`);
    }

    const placeIds = normalizeIds(script.placeIds, "placeIds", script.id);
    const currentUniverseIds = normalizeIds(script.universeIds, "universeIds", script.id);
    if (!placeIds.length && currentUniverseIds.length) {
      fail(`${script.id} has universeIds but no placeIds`);
    }
    if (!placeIds.length) continue;

    gameLinked += 1;
    const resolvedUniverseIds = [...new Set(await Promise.all(placeIds.map(resolveUniverseId)))]
      .sort((a, b) => a.localeCompare(b));
    if (JSON.stringify(currentUniverseIds) !== JSON.stringify(resolvedUniverseIds)) {
      if (!writeChanges) {
        fail(`${script.id}.universeIds should be ${JSON.stringify(resolvedUniverseIds)}`);
      }
      script.universeIds = resolvedUniverseIds;
      changed = true;
    }
  }

  if (writeChanges && changed) {
    fs.writeFileSync(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`, "utf8");
  }

  console.log(
    `Validated ${catalog.scripts.length} scripts (${gameLinked} game-linked).` +
      (changed ? " Updated universe mappings." : " Universe mappings are current.")
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
