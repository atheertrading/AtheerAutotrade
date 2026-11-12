import assert from "node:assert/strict";
import test from "node:test";
import {
  LOCAL_IPC_MAX_FRAME_BYTES,
  serveStdioIpc
} from "../dist/api/stdio-ipc.js";

const protocol = "atheer.local-ipc";

function request(id, method, payload = {}) {
  return JSON.stringify({
    protocol,
    version: 1,
    kind: "request",
    id,
    method,
    payload
  }) + "\n";
}

async function runSession(chunks) {
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

  await serveStdioIpc(input(), output);
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
  assert.deepEqual(responses[0].result.capabilities, ["system.ping"]);
  assert.equal(responses[1].ok, true);
  assert.deepEqual(responses[1].result, { status: "alive" });
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
