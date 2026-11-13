import assert from "node:assert/strict";
import test from "node:test";
import { spawn } from "node:child_process";
import {
  createCipheriv,
  createPublicKey,
  diffieHellman,
  generateKeyPairSync,
  hkdfSync,
  randomBytes
} from "node:crypto";
import {
  LOCAL_IPC_MAX_FRAME_BYTES,
  serveStdioIpc
} from "../dist/api/stdio-ipc.js";

const protocol = "atheer.local-ipc";
const testKeyPair = generateKeyPairSync("x25519");
const clientPublicKey = testKeyPair.publicKey
  .export({ format: "der", type: "spki" })
  .subarray(-32)
  .toString("base64");

function createFakeBroker() {
  return {
    setCredentials() {},
    async connect() { return { connected: true, environment: "demo" }; },
    status() { return { connected: false, environment: null }; },
    disconnect() {},
    async searchMarkets() { return { markets: [] }; },
    async getHistoricalPrices() { return { prices: [] }; },
    async getAccounts() { return { observedAt: "2026-11-14T00:00:00.000Z", accounts: [] }; },
    async getAccountPreferences() {
      return { observedAt: "2026-11-14T00:00:00.000Z", hedgingMode: false, leverages: {} };
    },
    async getPositions() { return { observedAt: "2026-11-14T00:00:00.000Z", positions: [] }; },
    async getWorkingOrders() { return { observedAt: "2026-11-14T00:00:00.000Z", workingOrders: [] }; },
    async startMarketDataStream() {},
    stopMarketDataStream() {}
  };
}

function request(id, method, payload = {}) {
  const requestPayload = method === "system.hello" ? { ...payload, clientPublicKey } : payload;
  return JSON.stringify({
    protocol,
    version: 2,
    kind: "request",
    id,
    method,
    payload: requestPayload
  }) + "\n";
}

async function runSession(chunks, broker = createFakeBroker()) {
  const output = {
    value: "",
    write(chunk) {
      this.value += chunk;
      return true;
    },
    once() {
      throw new Error("drain should not be requested by the test writer");
    }
  };

  async function* input() {
    for (const chunk of chunks) yield chunk;
  }

  await serveStdioIpc(input(), output, broker);
  return output.value.split("\n").filter(Boolean).map((line) => JSON.parse(line));
}

const encoder = new TextEncoder();

test("handshake and ping work across fragmented UTF-8 input", async () => {
  const input = request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133", "system.hello", {
    clientVersion: "0.1.0"
  }) + request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52", "system.ping");

  const bytes = encoder.encode(input);
  const responses = await runSession([
    bytes.slice(0, 13),
    bytes.slice(13, 47),
    bytes.slice(47)
  ]);

  assert.equal(responses.length, 2);
  assert.equal(responses[0].ok, true);
  assert.ok(responses[0].result.capabilities.includes("system.ping"));
  assert.ok(responses[0].result.capabilities.includes("broker.connect"));
  assert.ok(responses[0].result.capabilities.includes("broker.stream.start"));
  assert.ok(responses[0].result.capabilities.includes("broker.stream.stop"));
  assert.ok(responses[0].result.capabilities.includes("broker.accounts"));
  assert.ok(responses[0].result.capabilities.includes("broker.accountPreferences"));
  assert.ok(responses[0].result.capabilities.includes("broker.positions"));
  assert.ok(responses[0].result.capabilities.includes("broker.workingOrders"));
  assert.equal(responses[0].result.keyAgreement.algorithm, "X25519-HKDF-SHA256-AES-256-GCM");
  assert.equal(responses[1].ok, true);
  assert.deepEqual(responses[1].result, { status: "alive" });
});

test("accepts only one encrypted credential submission per child session", async () => {
  const output = {
    value: "",
    write(chunk) { this.value += chunk; return true; },
    once() { throw new Error("drain should not be requested by the test writer"); }
  };

  async function* input() {
    yield encoder.encode(request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133", "system.hello", {
      clientVersion: "0.1.0"
    }));

    const hello = JSON.parse(output.value.split("\n")[0]);
    const agreement = hello.result.keyAgreement;
    const peer = createPublicKey({
      key: Buffer.concat([
        Buffer.from("302a300506032b656e032100", "hex"),
        Buffer.from(agreement.publicKey, "base64")
      ]),
      format: "der",
      type: "spki"
    });
    const shared = diffieHellman({ privateKey: testKeyPair.privateKey, publicKey: peer });
    const key = Buffer.from(hkdfSync(
      "sha256",
      shared,
      Buffer.from(agreement.salt, "base64"),
      Buffer.from("atheer.local-ipc.capitalcom.credentials.v1", "utf8"),
      32
    ));
    const nonce = randomBytes(12);
    const plaintext = Buffer.from(JSON.stringify({
      apiKey: "fixture-api-key",
      identifier: "fixture@example.invalid",
      password: "fixture-password"
    }));
    const cipher = createCipheriv("aes-256-gcm", key, nonce);
    const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
    const envelope = {
      algorithm: "AES-256-GCM",
      nonce: nonce.toString("base64"),
      ciphertext: ciphertext.toString("base64"),
      tag: cipher.getAuthTag().toString("base64")
    };

    yield encoder.encode(request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52", "broker.credentials.submit", { envelope }));
    yield encoder.encode(request("a2d20bb2-89e6-46a2-8d5f-86a0bde87b53", "broker.credentials.submit", { envelope }));
    key.fill(0);
    shared.fill(0);
    plaintext.fill(0);
  }

  await serveStdioIpc(input(), output, createFakeBroker());
  const responses = output.value.split("\n").filter(Boolean).map((line) => JSON.parse(line));
  assert.equal(responses.length, 3);
  assert.equal(responses[1].ok, true);
  assert.equal(responses[2].error.code, "CREDENTIALS_ALREADY_SUBMITTED");
});

test("rejects application methods before handshake and closes the session", async () => {
  const responses = await runSession([
    encoder.encode(request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133", "system.ping"))
  ]);

  assert.equal(responses.length, 1);
  assert.equal(responses[0].error.code, "HANDSHAKE_REQUIRED");
});

test("rejects duplicate request identifiers", async () => {
  const input = request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133", "system.hello", {
    clientVersion: "0.1.0"
  }) + request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52", "system.ping")
    + request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52", "system.ping");

  const responses = await runSession([encoder.encode(input)]);
  assert.equal(responses.length, 3);
  assert.equal(responses[2].error.code, "DUPLICATE_REQUEST_ID");
});

test("unknown methods return a bounded error without ending the session", async () => {
  const input = request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133", "system.hello", {
    clientVersion: "0.1.0"
  }) + request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52", "filesystem.read");

  const responses = await runSession([encoder.encode(input)]);
  assert.equal(responses.length, 2);
  assert.equal(responses[1].error.code, "METHOD_NOT_FOUND");
  assert.equal("stack" in responses[1].error, false);
});

test("rejects malformed JSON", async () => {
  const responses = await runSession([encoder.encode("{not-json}\n")]);
  assert.equal(responses.length, 1);
  assert.equal(responses[0].error.code, "INVALID_FRAME");
});

test("rejects frames larger than the protocol limit", async () => {
  const oversized = new Uint8Array(LOCAL_IPC_MAX_FRAME_BYTES + 1).fill(0x61);
  const responses = await runSession([oversized]);
  assert.equal(responses.length, 1);
  assert.equal(responses[0].error.code, "FRAME_TOO_LARGE");
});

test("rejects non-empty ping payloads", async () => {
  const input = request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133", "system.hello", {
    clientVersion: "0.1.0"
  }) + request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52", "system.ping", {
    unexpected: true
  });

  const responses = await runSession([encoder.encode(input)]);
  assert.equal(responses[1].error.code, "INVALID_PAYLOAD");
});
test("rejects unsupported protocol versions explicitly", async () => {
  const unsupported = JSON.stringify({
    protocol,
    version: 99,
    kind: "request",
    id: "f2b66c1b-8c25-4c35-ae80-b0d59d7a9133",
    method: "system.hello",
    payload: { clientVersion: "0.1.0" }
  }) + "\n";

  const responses = await runSession([encoder.encode(unsupported)]);
  assert.equal(responses.length, 1);
  assert.equal(responses[0].error.code, "PROTOCOL_VERSION_UNSUPPORTED");
});

function collectText(stream) {
  return new Promise((resolve, reject) => {
    let value = "";
    stream.setEncoding("utf8");
    stream.on("data", (chunk) => { value += chunk; });
    stream.on("error", reject);
    stream.on("end", () => resolve(value));
  });
}

test("production stdio transport serves child-process requests with protocol-only stdout", { timeout: 5000 }, async () => {
  const child = spawn(process.execPath, ["dist/server.js", "--transport=stdio"], {
    stdio: ["pipe", "pipe", "pipe"]
  });

  const stdout = collectText(child.stdout);
  const stderr = collectText(child.stderr);
  const closed = new Promise((resolve) => {
    child.once("close", (code, signal) => resolve({ code, signal }));
  });

  child.stdin.end(
    request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133", "system.hello", {
      clientVersion: "0.1.0"
    }) + request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52", "system.ping")
  );

  const result = await closed;
  const output = await stdout;
  const diagnostics = await stderr;

  assert.deepEqual(result, { code: 0, signal: null });
  assert.equal(diagnostics, "");
  const responses = output.split("\n").filter(Boolean).map((line) => JSON.parse(line));
  assert.equal(responses.length, 2);
  assert.equal(responses[0].result.protocolVersion, 2);
  assert.deepEqual(responses[1].result, { status: "alive" });
});



test("read-only account IPC methods return snapshots and reject mutation payloads", async () => {
  const broker={
    async getAccounts(){return {observedAt:"2026-11-13T10:00:00.000Z",accounts:[{accountId:"a1"}]};},
    async getAccountPreferences(){return {observedAt:"2026-11-13T10:00:00.000Z",hedgingMode:false,leverages:{}};},
    async getPositions(){return {observedAt:"2026-11-13T10:00:00.000Z",positions:[{position:{dealId:"p1"}}]};},
    async getWorkingOrders(){return {observedAt:"2026-11-13T10:00:00.000Z",workingOrders:[{workingOrderData:{dealId:"w1"}}]};},
    disconnect(){}
  };
  const input=request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133","system.hello",{clientVersion:"0.1.0"})+
    request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52","broker.accounts")+
    request("a2d20bb2-89e6-46a2-8d5f-86a0bde87b53","broker.accountPreferences")+
    request("b2d20bb2-89e6-46a2-8d5f-86a0bde87b54","broker.positions")+
    request("c2d20bb2-89e6-46a2-8d5f-86a0bde87b55","broker.workingOrders");
  const responses=await runSession([encoder.encode(input)],broker);
  assert.equal(responses.length,5);
  assert.deepEqual(responses.slice(1).map(x=>x.ok),[true,true,true,true]);
  assert.equal(responses[1].result.accounts[0].accountId,"a1");
  assert.equal(responses[2].result.hedgingMode,false);
  assert.equal(responses[3].result.positions[0].position.dealId,"p1");
  assert.equal(responses[4].result.workingOrders[0].workingOrderData.dealId,"w1");
  const invalidBroker={async getAccounts(){throw new Error("must not be called");},disconnect(){}};
  const invalid=await runSession([encoder.encode(request("f2b66c1b-8c25-4c35-ae80-b0d59d7a9133","system.hello",{clientVersion:"0.1.0"})+request("e2d20bb2-89e6-46a2-8d5f-86a0bde87b52","broker.accounts",{accountId:"x"}))],invalidBroker);
  assert.equal(invalid[1].error.code,"INVALID_PAYLOAD");
});
