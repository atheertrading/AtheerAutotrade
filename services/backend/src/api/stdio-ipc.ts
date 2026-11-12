import { CapitalComRuntime } from "../modules/broker-adapters/capital-com/capital-com-runtime.js";
import { IpcSecretChannel } from "../security/ipc-secret-channel.js";

export const LOCAL_IPC_PROTOCOL = "atheer.local-ipc";
export const LOCAL_IPC_VERSION = 2;
export const LOCAL_IPC_MAX_FRAME_BYTES = 65_536;
export const LOCAL_IPC_MAX_SESSION_REQUESTS = 4_096;

export interface IpcWritable {
  write(chunk: string): boolean;
  once(event: "drain", listener: () => void): unknown;
}

type JsonObject = Record<string, unknown>;

interface IpcRequest {
  protocol: string;
  version: number;
  kind: "request";
  id: string;
  method: string;
  payload: JsonObject;
}

function isObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isUuid(value: unknown): value is string {
  return typeof value === "string"
    && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

function hasExactKeys(value: JsonObject, expected: readonly string[]): boolean {
  const actual = Object.keys(value);
  return actual.length === expected.length
    && expected.every((key) => Object.prototype.hasOwnProperty.call(value, key));
}

async function writeResponse(output: IpcWritable, response: JsonObject): Promise<void> {
  const frame = `${JSON.stringify(response)}\n`;
  if (output.write(frame)) return;
  await new Promise<void>((resolve) => output.once("drain", resolve));
}

function success(id: string, result: JsonObject): JsonObject {
  return { protocol: LOCAL_IPC_PROTOCOL, version: LOCAL_IPC_VERSION, kind: "response", id, ok: true, result };
}

function failure(id: string | null, code: string, message: string): JsonObject {
  return { protocol: LOCAL_IPC_PROTOCOL, version: LOCAL_IPC_VERSION, kind: "response", id, ok: false, error: { code, message } };
}

function parseRequest(value: unknown): IpcRequest | null {
  if (!isObject(value) || !hasExactKeys(value, ["protocol", "version", "kind", "id", "method", "payload"])) return null;
  if (value.protocol !== LOCAL_IPC_PROTOCOL || value.version !== LOCAL_IPC_VERSION
    || value.kind !== "request" || !isUuid(value.id)
    || typeof value.method !== "string" || value.method.length < 1 || value.method.length > 64
    || !isObject(value.payload)) return null;
  return value as unknown as IpcRequest;
}

function safeError(error: unknown): { code: string; message: string } {
  if (error instanceof TypeError) return { code: "INVALID_PAYLOAD", message: error.message.slice(0, 300) };
  if (error instanceof Error && error.message === "Capital.com credentials have not been submitted.") {
    return { code: "CREDENTIALS_REQUIRED", message: "Save valid Capital.com credentials before connecting." };
  }
  if (error instanceof Error && error.message === "Capital.com is not connected.") {
    return { code: "BROKER_NOT_CONNECTED", message: "Establish a Capital.com session first." };
  }
  if (error instanceof Error && error.name === "CapitalComApiError") {
    return { code: "BROKER_API_ERROR", message: error.message };
  }
  return { code: "BROKER_OPERATION_FAILED", message: "The Capital.com operation could not be completed." };
}

/** Serve one parent-owned stdio IPC session. Secrets are accepted only as authenticated ciphertext. */
export async function serveStdioIpc(
  input: AsyncIterable<Uint8Array>,
  output: IpcWritable,
  broker = new CapitalComRuntime()
): Promise<void> {
  const seenRequestIds = new Set<string>();
  const secretChannel = new IpcSecretChannel();
  let handshakeComplete = false;
  let credentialsSubmitted = false;
  let frame: number[] = [];

  const respondAndStop = async (id: string | null, code: string, message: string): Promise<void> => {
    await writeResponse(output, failure(id, code, message));
  };

  try {
    for await (const chunk of input) {
      for (const byte of chunk) {
        if (byte !== 0x0a) {
          frame.push(byte);
          if (frame.length > LOCAL_IPC_MAX_FRAME_BYTES) {
            await respondAndStop(null, "FRAME_TOO_LARGE", "The IPC frame exceeds the permitted size.");
            return;
          }
          continue;
        }

        if (frame.length > 0 && frame[frame.length - 1] === 0x0d) frame.pop();
        if (frame.length === 0) {
          await respondAndStop(null, "INVALID_FRAME", "Empty IPC frames are not permitted.");
          return;
        }

        let parsed: unknown;
        try {
          parsed = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(Uint8Array.from(frame))) as unknown;
        } catch {
          await respondAndStop(null, "INVALID_FRAME", "The IPC frame is not valid UTF-8 JSON.");
          return;
        } finally {
          frame = [];
        }

        if (isObject(parsed) && parsed.protocol === LOCAL_IPC_PROTOCOL
          && parsed.version !== LOCAL_IPC_VERSION && isUuid(parsed.id)) {
          await respondAndStop(parsed.id, "PROTOCOL_VERSION_UNSUPPORTED", "The IPC protocol version is not supported.");
          return;
        }

        const request = parseRequest(parsed);
        if (!request) {
          await respondAndStop(null, "INVALID_ENVELOPE", "The IPC request envelope is invalid or unsupported.");
          return;
        }
        if (seenRequestIds.has(request.id)) {
          await respondAndStop(request.id, "DUPLICATE_REQUEST_ID", "The request identifier was already used.");
          return;
        }
        if (seenRequestIds.size >= LOCAL_IPC_MAX_SESSION_REQUESTS) {
          await respondAndStop(request.id, "SESSION_REQUEST_LIMIT", "The IPC request limit was reached.");
          return;
        }
        seenRequestIds.add(request.id);

        if (!handshakeComplete) {
          if (request.method !== "system.hello"
            || !hasExactKeys(request.payload, ["clientVersion", "clientPublicKey"])
            || typeof request.payload.clientVersion !== "string"
            || request.payload.clientVersion.length < 1 || request.payload.clientVersion.length > 64) {
            await respondAndStop(request.id, "HANDSHAKE_REQUIRED", "A valid encrypted-channel handshake is required first.");
            return;
          }
          try {
            secretChannel.establish(request.payload.clientPublicKey);
          } catch {
            await respondAndStop(request.id, "KEY_AGREEMENT_FAILED", "The secure IPC channel could not be established.");
            return;
          }
          handshakeComplete = true;
          await writeResponse(output, success(request.id, {
            protocolVersion: LOCAL_IPC_VERSION,
            service: "atheerautotrade-backend",
            capabilities: [
              "system.ping",
              "broker.credentials.submit",
              "broker.connect",
              "broker.status",
              "broker.disconnect",
              "broker.marketSearch",
              "broker.historicalPrices",
              "broker.stream.start",
              "broker.stream.stop"
            ],
            keyAgreement: {
              algorithm: "X25519-HKDF-SHA256-AES-256-GCM",
              ...secretChannel.handshakeParameters
            }
          }));
          continue;
        }

        if (request.method === "system.hello") {
          await respondAndStop(request.id, "INVALID_ENVELOPE", "The IPC handshake can only occur once per session.");
          return;
        }

        try {
          switch (request.method) {
            case "system.ping": {
              if (Object.keys(request.payload).length !== 0) throw new TypeError("system.ping does not accept payload fields.");
              await writeResponse(output, success(request.id, { status: "alive" }));
              break;
            }
            case "broker.credentials.submit": {
              if (credentialsSubmitted) {
                await writeResponse(output, failure(request.id, "CREDENTIALS_ALREADY_SUBMITTED", "Credential transfer is one-shot for each backend process session."));
                break;
              }
              if (!hasExactKeys(request.payload, ["envelope"])) throw new TypeError("Encrypted credentials envelope is required.");
              const plaintext = secretChannel.decrypt(request.payload.envelope);
              try {
                const credentials = JSON.parse(plaintext.toString("utf8")) as unknown;
                broker.setCredentials(credentials);
                credentialsSubmitted = true;
              } finally {
                plaintext.fill(0);
              }
              await writeResponse(output, success(request.id, { accepted: true, storage: "process-memory-only" }));
              break;
            }
            case "broker.connect": {
              if (!hasExactKeys(request.payload, ["environment"]) || request.payload.environment !== "demo") {
                throw new TypeError("Only the explicitly selected Capital.com Demo environment is supported.");
              }
              await writeResponse(output, success(request.id, await broker.connect("demo")));
              break;
            }
            case "broker.status": {
              if (Object.keys(request.payload).length !== 0) throw new TypeError("broker.status does not accept payload fields.");
              await writeResponse(output, success(request.id, broker.status()));
              break;
            }
            case "broker.disconnect": {
              if (Object.keys(request.payload).length !== 0) throw new TypeError("broker.disconnect does not accept payload fields.");
              broker.disconnect();
              await writeResponse(output, success(request.id, { connected: false }));
              break;
            }
            case "broker.marketSearch": {
              if (!hasExactKeys(request.payload, ["searchTerm"]) || typeof request.payload.searchTerm !== "string") {
                throw new TypeError("searchTerm is required.");
              }
              const result = await broker.searchMarkets(request.payload.searchTerm);
              await writeResponse(output, success(request.id, { markets: result.markets }));
              break;
            }
            case "broker.stream.start": {
              if (!hasExactKeys(request.payload, ["epics", "resolutions", "candleType"])
                || !Array.isArray(request.payload.epics)
                || !request.payload.epics.every((epic) => typeof epic === "string")
                || !Array.isArray(request.payload.resolutions)
                || !request.payload.resolutions.every((resolution) => typeof resolution === "string")
                || (request.payload.candleType !== "classic" && request.payload.candleType !== "heikin-ashi")) {
                throw new TypeError("epics, resolutions, and a supported candleType are required.");
              }
              await broker.startMarketDataStream({
                epics: request.payload.epics as string[],
                resolutions: request.payload.resolutions as import("../modules/broker-adapters/capital-com/capital-com-client.js").CapitalComResolution[],
                candleType: request.payload.candleType
              }, (event, payload) => {
                void writeResponse(output, {
                  protocol: LOCAL_IPC_PROTOCOL,
                  version: LOCAL_IPC_VERSION,
                  kind: "event",
                  event,
                  payload
                }).catch(() => undefined);
              });
              await writeResponse(output, success(request.id, { started: true }));
              break;
            }
            case "broker.stream.stop": {
              if (Object.keys(request.payload).length !== 0) throw new TypeError("broker.stream.stop does not accept payload fields.");
              broker.stopMarketDataStream();
              await writeResponse(output, success(request.id, { stopped: true }));
              break;
            }
            case "broker.historicalPrices": {
              if (!hasExactKeys(request.payload, ["epic", "resolution", "max"])
                || typeof request.payload.epic !== "string"
                || typeof request.payload.resolution !== "string"
                || typeof request.payload.max !== "number") {
                throw new TypeError("epic, resolution, and max are required.");
              }
              const result = await broker.getHistoricalPrices(
                request.payload.epic,
                request.payload.resolution,
                request.payload.max
              );
              await writeResponse(output, success(request.id, {
                prices: result.prices,
                ...(result.instrumentType ? { instrumentType: result.instrumentType } : {})
              }));
              break;
            }
            default:
              await writeResponse(output, failure(request.id, "METHOD_NOT_FOUND", "The requested IPC method is not available."));
          }
        } catch (error) {
          const safe = safeError(error);
          await writeResponse(output, failure(request.id, safe.code, safe.message));
        }
      }
    }

    if (frame.length > 0) {
      await respondAndStop(null, "INVALID_FRAME", "The IPC stream ended with an incomplete frame.");
    }
  } finally {
    secretChannel.destroy();
    broker.disconnect();
  }
}
