import type { IncomingMessage, ServerResponse } from "node:http";
import { handleHealth } from "./health.js";

export function route(request: IncomingMessage, response: ServerResponse): void {
  if (request.method === "GET" && request.url === "/health") {
    handleHealth(request, response);
    return;
  }

  response.writeHead(404, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  response.end(JSON.stringify({
    error: {
      code: "NOT_FOUND",
      message: "The requested resource was not found."
    }
  }));
}
