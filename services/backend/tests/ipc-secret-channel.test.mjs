import assert from "node:assert/strict";
import test from "node:test";
import {
  createCipheriv,
  createPublicKey,
  diffieHellman,
  generateKeyPairSync,
  hkdfSync,
  randomBytes
} from "node:crypto";
import { IpcSecretChannel } from "../dist/security/ipc-secret-channel.js";

const spkiPrefix = Buffer.from("302a300506032b656e032100", "hex");
const info = Buffer.from("atheer.local-ipc.capitalcom.credentials.v1", "utf8");

test("X25519/HKDF/AES-256-GCM secret channel decrypts only authenticated ciphertext", () => {
  const channel = new IpcSecretChannel();
  const clientPair = generateKeyPairSync("x25519");
  const clientPublicRaw = clientPair.publicKey
    .export({ format: "der", type: "spki" })
    .subarray(-32);

  channel.establish(clientPublicRaw.toString("base64"));
  const parameters = channel.handshakeParameters;
  const serverPublicRaw = Buffer.from(parameters.publicKey, "base64");
  const serverPublic = createPublicKey({
    key: Buffer.concat([spkiPrefix, serverPublicRaw]),
    format: "der",
    type: "spki"
  });
  const shared = diffieHellman({ privateKey: clientPair.privateKey, publicKey: serverPublic });
  const key = Buffer.from(hkdfSync(
    "sha256",
    shared,
    Buffer.from(parameters.salt, "base64"),
    info,
    32
  ));

  const nonce = randomBytes(12);
  const plaintext = Buffer.from(JSON.stringify({
    apiKey: "test-api-key",
    identifier: "demo@example.invalid",
    password: "test-password"
  }));
  const cipher = createCipheriv("aes-256-gcm", key, nonce);
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const envelope = {
    algorithm: "AES-256-GCM",
    nonce: nonce.toString("base64"),
    ciphertext: ciphertext.toString("base64"),
    tag: cipher.getAuthTag().toString("base64")
  };

  assert.deepEqual(JSON.parse(channel.decrypt(envelope).toString("utf8")), JSON.parse(plaintext.toString("utf8")));
  assert.throws(() => channel.decrypt({ ...envelope, tag: randomBytes(16).toString("base64") }));
  channel.destroy();
  key.fill(0);
  shared.fill(0);
});
