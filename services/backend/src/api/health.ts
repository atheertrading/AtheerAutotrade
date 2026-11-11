import type { IncomingMessage, ServerResponse } from "node:http";
import { environment } from "../config/environment.js";

export function handleHealth(_request: IncomingMessage, response: ServerResponse): void {
  response.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  response.end(JSON.stringify({
    service: environment.serviceName,
    status: "healthy",
    version: environment.applicationVersion,
    timestamp: new Date().toISOString()
  }));
}
