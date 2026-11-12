export const LOCAL_IPC_PROTOCOL = "atheer.local-ipc";
export const LOCAL_IPC_VERSION = 1;
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
  return {
    protocol: LOCAL_IPC_PROTOCOL,
    version: LOCAL_IPC_VERSION,
    kind: "response",
    id,
    ok: true,
    result
  };
}

function failure(id: string | null, code: string, message: string): JsonObject {
  return {
    protocol: LOCAL_IPC_PROTOCOL,
    version: LOCAL_IPC_VERSION,
    kind: "response",
    id,
    ok: false,
    error: { code, message }
  };
}

function parseRequest(value: unknown): IpcRequest | null {
  if (!isObject(value) || !hasExactKeys(value, [
    "protocol", "version", "kind", "id", "method", "payload"
  ])) return null;

  if (value.protocol !== LOCAL_IPC_PROTOCOL
    || value.version !== LOCAL_IPC_VERSION
    || value.kind !== "request"
    || !isUuid(value.id)
    || typeof value.method !== "string"
    || value.method.length < 1
    || value.method.length > 64
    || !isObject(value.payload)) return null;

  return value as unknown as IpcRequest;
}

/**
 * Serve one parent-owned stdio IPC session.
 *
 * The caller must provide the child's stdin as an AsyncIterable<Uint8Array>
 * and stdout as the writable response channel. No network listener is opened.
 * Stdout is protocol-only; this function never writes diagnostics.
 */
export async function serveStdioIpc(
  input: AsyncIterable<Uint8Array>,
  output: IpcWritable
): Promise<void> {
  const seenRequestIds = new Set<string>();
  let handshakeComplete = false;
  let frame: number[] = [];

  const respondAndStop = async (
    id: string | null,
    code: string,
    message: string
  ): Promise<void> => {
    await writeResponse(output, failure(id, code, message));
  };

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
        const text = new TextDecoder("utf-8", { fatal: true }).decode(Uint8Array.from(frame));
        parsed = JSON.parse(text) as unknown;
      } catch {
        await respondAndStop(null, "INVALID_FRAME", "The IPC frame is not valid UTF-8 JSON.");
        return;
      } finally {
        frame = [];
      }

      if (isObject(parsed)
        && parsed.protocol === LOCAL_IPC_PROTOCOL
        && parsed.version !== LOCAL_IPC_VERSION
        && isUuid(parsed.id)) {
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
        await respondAndStop(request.id, "SESSION_REQUEST_LIMIT", "The IPC session request limit was reached.");
        return;
      }
      seenRequestIds.add(request.id);

      if (!handshakeComplete) {
        if (request.method !== "system.hello"
          || !hasExactKeys(request.payload, ["clientVersion"])
          || typeof request.payload.clientVersion !== "string"
          || request.payload.clientVersion.length < 1
          || request.payload.clientVersion.length > 64) {
          await respondAndStop(request.id, "HANDSHAKE_REQUIRED", "A valid system.hello request is required first.");
          return;
        }

        handshakeComplete = true;
        await writeResponse(output, success(request.id, {
          protocolVersion: LOCAL_IPC_VERSION,
          service: "atheerautotrade-backend",
          capabilities: ["system.ping"]
        }));
        continue;
      }

      if (request.method === "system.hello") {
        await respondAndStop(request.id, "INVALID_ENVELOPE", "The IPC handshake can only occur once per session.");
        return;
      }

      if (request.method === "system.ping") {
        if (Object.keys(request.payload).length !== 0) {
          await writeResponse(output, failure(request.id, "INVALID_PAYLOAD", "system.ping does not accept payload fields."));
          continue;
        }
        await writeResponse(output, success(request.id, { status: "alive" }));
        continue;
      }

      await writeResponse(output, failure(request.id, "METHOD_NOT_FOUND", "The requested IPC method is not available."));
    }
  }

  if (frame.length > 0) {
    await respondAndStop(null, "INVALID_FRAME", "The IPC stream ended with an incomplete frame.");
  }
}
