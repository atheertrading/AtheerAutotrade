import {
  createDecipheriv,
  createPublicKey,
  diffieHellman,
  generateKeyPairSync,
  hkdfSync,
  randomBytes,
  type KeyObject
} from "node:crypto";

const SPKI_X25519_PREFIX = Buffer.from("302a300506032b656e032100", "hex");
const KEY_INFO = Buffer.from("atheer.local-ipc.capitalcom.credentials.v1", "utf8");

export interface EncryptedSecretEnvelope {
  readonly algorithm: "AES-256-GCM";
  readonly nonce: string;
  readonly ciphertext: string;
  readonly tag: string;
}

function decodeBase64(value: unknown, expectedLength: number, field: string): Buffer {
  if (typeof value !== "string") throw new TypeError(`${field} must be base64 text.`);
  const decoded = Buffer.from(value, "base64");
  if (decoded.length !== expectedLength || decoded.toString("base64") !== value) {
    throw new TypeError(`${field} has an invalid encoding or length.`);
  }
  return decoded;
}

/**
 * Per-child-session ephemeral X25519 + HKDF + AES-256-GCM channel.
 * The private key and derived key remain in process memory only.
 */
export class IpcSecretChannel {
  private readonly privateKey: KeyObject;
  private readonly salt = randomBytes(32);
  private readonly rawPublicKey: Buffer;
  private sessionKey: Buffer | undefined;

  constructor() {
    const pair = generateKeyPairSync("x25519");
    this.privateKey = pair.privateKey;
    this.rawPublicKey = pair.publicKey.export({ format: "der", type: "spki" }).subarray(-32);
  }

  get handshakeParameters(): { readonly publicKey: string; readonly salt: string } {
    return Object.freeze({
      publicKey: this.rawPublicKey.toString("base64"),
      salt: this.salt.toString("base64")
    });
  }

  establish(clientPublicKeyBase64: unknown): void {
    if (this.sessionKey) throw new Error("The IPC secret channel is already established.");
    const clientRaw = decodeBase64(clientPublicKeyBase64, 32, "clientPublicKey");
    const clientPublicKey = createPublicKey({
      key: Buffer.concat([SPKI_X25519_PREFIX, clientRaw]),
      format: "der",
      type: "spki"
    });
    const sharedSecret = diffieHellman({ privateKey: this.privateKey, publicKey: clientPublicKey });
    this.sessionKey = Buffer.from(hkdfSync("sha256", sharedSecret, this.salt, KEY_INFO, 32));
    sharedSecret.fill(0);
  }

  decrypt(envelope: unknown): Buffer {
    if (!this.sessionKey) throw new Error("The IPC secret channel is not established.");
    if (!envelope || typeof envelope !== "object" || Array.isArray(envelope)) {
      throw new TypeError("Encrypted credential envelope is invalid.");
    }
    const value = envelope as Record<string, unknown>;
    if (value.algorithm !== "AES-256-GCM") throw new TypeError("Unsupported credential encryption algorithm.");
    const nonce = decodeBase64(value.nonce, 12, "nonce");
    const ciphertext = decodeBase64Variable(value.ciphertext, "ciphertext");
    const tag = decodeBase64(value.tag, 16, "tag");
    const decipher = createDecipheriv("aes-256-gcm", this.sessionKey, nonce);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  }

  destroy(): void {
    this.sessionKey?.fill(0);
    this.sessionKey = undefined;
  }
}

function decodeBase64Variable(value: unknown, field: string): Buffer {
  if (typeof value !== "string" || value.length > 16_384) {
    throw new TypeError(`${field} is invalid.`);
  }
  const decoded = Buffer.from(value, "base64");
  if (decoded.toString("base64") !== value) throw new TypeError(`${field} has an invalid encoding.`);
  return decoded;
}
