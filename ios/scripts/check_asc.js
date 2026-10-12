// Diagnostic: can the App Store Connect key saved in GitHub talk to Apple?
// Prints only status numbers and counts. Never prints the key.
const fs = require("fs");
const crypto = require("crypto");
const os = require("os");

const keyId = process.env.ASC_KEY_ID;
const issuer = process.env.ASC_ISSUER_ID;
const p8 = fs.readFileSync(`${os.homedir()}/.appstoreconnect/private_keys/AuthKey_${keyId}.p8`, "utf8");

const b64u = (b) => Buffer.from(b).toString("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
function jwt() {
  const now = Math.floor(Date.now() / 1000);
  const data = b64u(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" })) + "." +
    b64u(JSON.stringify({ iss: issuer, iat: now, exp: now + 900, aud: "appstoreconnect-v1" }));
  return data + "." + b64u(crypto.sign("sha256", Buffer.from(data), { key: p8, dsaEncoding: "ieee-p1363" }));
}
async function get(path) {
  const r = await fetch("https://api.appstoreconnect.apple.com" + path, { headers: { Authorization: "Bearer " + jwt() } });
  let j = null;
  try { j = await r.json(); } catch (_) {}
  return { status: r.status, j };
}

(async () => {
  console.log("key id length:", (keyId || "").length, "| issuer length:", (issuer || "").length);
  const b = await get("/v1/bundleIds?limit=50&fields[bundleIds]=identifier");
  console.log("bundleIds:", b.status, "count:", b.j?.data?.length);
  const c = await get("/v1/certificates?limit=50");
  console.log("certificates:", c.status, "types:", (c.j?.data || []).map((x) => x.attributes.certificateType).join(",") || "none");
  const d = await get("/v1/devices?limit=50");
  console.log("devices:", d.status, "count:", d.j?.data?.length);
  const a = await get("/v1/apps?limit=50&fields[apps]=bundleId,name");
  console.log("apps:", a.status, (a.j?.data || []).map((x) => x.attributes.bundleId).join(",") || "none");
})();
