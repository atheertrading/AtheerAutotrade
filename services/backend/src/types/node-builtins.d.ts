/**
 * Narrow ambient declarations for the small Node.js built-in surface used by this
 * foundation. Expand these declarations deliberately as modules are added; this
 * avoids a second dependency while keeping current server code strictly checked.
 */
declare module "node:http" {
  export interface IncomingMessage {
    method?: string;
    url?: string;
  }

  export interface ServerResponse {
    headersSent: boolean;
    writeHead(statusCode: number, headers?: Record<string, string>): this;
    end(data?: string): this;
  }

  export interface Socket {
    end(data?: string): void;
  }

  export interface Server {
    listen(port: number, host: string, callback?: () => void): this;
    close(callback?: (error?: Error) => void): this;
    closeAllConnections(): void;
    on(event: "clientError", listener: (error: Error, socket: Socket) => void): this;
    on(event: "error", listener: (error: Error) => void): this;
  }

  export function createServer(
    listener: (request: IncomingMessage, response: ServerResponse) => void
  ): Server;
}

declare const process: {
  argv: string[];
  env: Record<string, string | undefined>;
  stdin: AsyncIterable<Uint8Array> & { destroy(): void };
  stdout: {
    write(chunk: string): boolean;
    once(event: "drain", listener: () => void): unknown;
  };
  exitCode: number | undefined;
  on(event: "SIGINT" | "SIGTERM", listener: () => void): void;
};

declare const console: {
  log(...values: unknown[]): void;
  error(...values: unknown[]): void;
};

declare function setTimeout(callback: () => void, milliseconds?: number): { unref(): void };
declare function clearTimeout(timeout: { unref(): void }): void;

declare module "node:crypto" {
  export interface KeyObject {
    export(options: { format: "der"; type: "spki" }): Buffer;
  }

  export interface DecipherGCM {
    setAuthTag(tag: Uint8Array): void;
    update(data: Uint8Array): Buffer;
    final(): Buffer;
  }

  export function generateKeyPairSync(type: "x25519"): {
    privateKey: KeyObject;
    publicKey: KeyObject;
  };
  export function createPublicKey(options: {
    key: Uint8Array;
    format: "der";
    type: "spki";
  }): KeyObject;
  export function diffieHellman(options: {
    privateKey: KeyObject;
    publicKey: KeyObject;
  }): Buffer;
  export function hkdfSync(
    digest: "sha256",
    key: Uint8Array,
    salt: Uint8Array,
    info: Uint8Array,
    keyLength: number
  ): ArrayBuffer;
  export function randomBytes(size: number): Buffer;
  export function createDecipheriv(
    algorithm: "aes-256-gcm",
    key: Uint8Array,
    iv: Uint8Array
  ): DecipherGCM;
}

interface Buffer extends Uint8Array {
  toString(encoding?: "utf8" | "base64" | "hex"): string;
  subarray(begin?: number, end?: number): Buffer;
}

declare const Buffer: {
  from(value: string, encoding?: "utf8" | "base64" | "hex"): Buffer;
  from(value: ArrayBuffer): Buffer;
  concat(values: readonly Uint8Array[]): Buffer;
};
