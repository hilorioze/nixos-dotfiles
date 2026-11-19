const EMPTY_PAYLOAD_SHA256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

const HOUR = 60 * 60;
const DAY = 24 * HOUR;

// object keys niks3 writes, as its own read proxy accepts them: https://github.com/Mic92/niks3/blob/95b8da7c3ef54b911c1fdea858feca310d7221ec/server/proxy.go#L153-L226
const NIX_BASE32 = "0123456789abcdfghijklmnpqrsvwxyz";

const narinfoRe = new RegExp(`^[${NIX_BASE32}]{32}\\.narinfo$`);
const narRe = new RegExp(`^nar/[${NIX_BASE32}]{52}\\.nar(\\.zst|\\.xz|\\.bz2)?$`);
const listingRe = new RegExp(`^[${NIX_BASE32}]{32}\\.ls$`);
const logRe = /^log\/[a-zA-Z0-9+._?=-]+\.drv$/;
const realisationsRe = /^realisations\/[a-z0-9]+:[a-zA-Z0-9+/=]+![a-zA-Z0-9+._?=-]+\.doi$/;

export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed\n", { status: 405, headers: { Allow: "GET, HEAD" } });
    }

    // drop the query string for better cache hits
    const key = safeDecode(new URL(request.url).pathname.slice(1)) || "index.html";

    if (!isValidCachePath(key)) {
      return new Response("Not Found\n", { status: 404 });
    }

    const originHost = `${env.B2_BUCKET}.${env.B2_ENDPOINT}`;
    const originPath = `/${canonicalUri(key)}`;

    const originHeaders = await signGet(originHost, originPath, env);

    // unsigned; on a cache miss cloudflare drops it to fetch the whole object and slices the range itself
    const range = request.headers.get("range");
    if (range) {
      originHeaders.set("range", range);
    }

    // cloudflare turns `HEAD` into `GET` on a cache miss, which breaks a signature over `HEAD`; always send `GET`
    const originResponse = await fetch(`https://${originHost}${originPath}`, {
      headers: originHeaders,
      cf: {
        cacheEverything: true,
        cacheTtlByStatus: { 200: edgeTtl(key), "201-599": 0 }, // a missing path may be pushed any moment
      },
    });

    const headers = new Headers(originResponse.headers);

    // nix resumes an interrupted nar download only after a response that advertised range support
    if (key.startsWith("nar/") && originResponse.ok) {
      headers.set("Accept-Ranges", "bytes");
    }

    // niks3 stores the metadata zstd-compressed, and b2 doesn't keep the encoding; nars stay as is, nix decompresses them itself
    if (originResponse.status === 200 && isZstdMetadata(key)) {
      headers.set("Content-Encoding", "zstd");
    }

    return new Response(request.method === "HEAD" ? null : originResponse.body, {
      status: originResponse.status,
      headers,
    });
  },
};

function isValidCachePath(key) {
  // store path names may contain `..` (e.g. `hm_..zlogout.drv`); reject only `..` segments
  if (key === ".." || key.startsWith("../") || key.endsWith("/..") || key.includes("/../")) {
    return false;
  }

  return key === "nix-cache-info" || key === "index.html" || narinfoRe.test(key) || narRe.test(key) || listingRe.test(key) || logRe.test(key) || realisationsRe.test(key);
}

function isZstdMetadata(key) {
  return key.endsWith(".narinfo") || key.endsWith(".ls") || key.startsWith("log/") || key.startsWith("realisations/");
}

function edgeTtl(key) {
  // nars are named by their hash and never change
  if (narRe.test(key)) {
    return 30 * DAY;
  }

  // niks3 rewrites them on start
  if (key === "nix-cache-info" || key === "index.html") {
    return HOUR;
  }

  // niks3 gc deletes the metadata along with the nars; serve a deleted narinfo for a day at most
  return DAY;
}

// percent-encode like aws sigv4 expects, keeping the slashes
function canonicalUri(key) {
  return key
    .split("/")
    .map((part) => encodeURIComponent(part).replace(/[!'()*]/g, (char) => `%${char.charCodeAt(0).toString(16).toUpperCase()}`))
    .join("/");
}

function safeDecode(value) {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

// aws sigv4 over the headers cloudflare passes to b2 unchanged; it drops `range` and the conditional headers on a cache miss
async function signGet(host, path, env) {
  const amzDate = new Date().toISOString().replace(/[:-]|\.\d{3}/g, "");
  const dateStamp = amzDate.slice(0, 8);

  const scope = `${dateStamp}/${env.B2_REGION}/s3/aws4_request`;

  const signedHeaders = {
    host,
    "x-amz-content-sha256": EMPTY_PAYLOAD_SHA256,
    "x-amz-date": amzDate,
  };
  const signedHeaderNames = Object.keys(signedHeaders).join(";");

  const canonicalRequest = [
    "GET",
    path,
    "", // no query string
    ...Object.entries(signedHeaders).map(([name, value]) => `${name}:${value}`),
    "",
    signedHeaderNames,
    EMPTY_PAYLOAD_SHA256,
  ].join("\n");

  const stringToSign = ["AWS4-HMAC-SHA256", amzDate, scope, hex(await sha256(canonicalRequest))].join("\n");

  let signingKey = utf8(`AWS4${env.B2_APPLICATION_KEY}`);
  for (const part of [dateStamp, env.B2_REGION, "s3", "aws4_request"]) {
    signingKey = await hmac(signingKey, part);
  }

  const signature = hex(await hmac(signingKey, stringToSign));

  return new Headers({
    "x-amz-content-sha256": EMPTY_PAYLOAD_SHA256,
    "x-amz-date": amzDate,

    authorization: `AWS4-HMAC-SHA256 Credential=${env.B2_APPLICATION_KEY_ID}/${scope}, SignedHeaders=${signedHeaderNames}, Signature=${signature}`,
  });
}

async function sha256(value) {
  return crypto.subtle.digest("SHA-256", utf8(value));
}

async function hmac(keyBytes, value) {
  const key = await crypto.subtle.importKey("raw", keyBytes, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);

  return new Uint8Array(await crypto.subtle.sign("HMAC", key, utf8(value)));
}

function utf8(value) {
  return new TextEncoder().encode(value);
}

function hex(buffer) {
  return [...new Uint8Array(buffer)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}
