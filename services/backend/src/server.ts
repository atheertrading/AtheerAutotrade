import { createServer } from "node:http";
import { environment } from "./config/environment.js";
import { route } from "./api/router.js";

const server = createServer((request, response) => {
  try {
    route(request, response);
  } catch (error) {
    console.error("Unhandled request error", error);
    if (!response.headersSent) {
      response.writeHead(500, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
    }
    response.end(JSON.stringify({
      error: {
        code: "INTERNAL_ERROR",
        message: "The request could not be completed."
      }
    }));
  }
});

server.on("error", (error) => {
  console.error("HTTP server failed", error);
  process.exitCode = 1;
});

server.on("clientError", (_error, socket) => {
  socket.end("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n");
});

server.listen(environment.port, environment.host, () => {
  console.log(`${environment.serviceName} listening on http://${environment.host}:${environment.port}`);
});

let shuttingDown = false;
function shutdown(signal: string): void {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`Received ${signal}; shutting down HTTP server.`);
  const timeout = setTimeout(() => {
    console.error("Graceful shutdown timed out.");
    process.exitCode = 1;
    server.closeAllConnections();
    server.close();
  }, 10_000);
  timeout.unref();
  server.close((error) => {
    clearTimeout(timeout);
    if (error) {
      console.error("HTTP server shutdown failed", error);
      process.exitCode = 1;
    }
  });
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
