import { createServer } from "node:http";
import { route } from "./api/router.js";
import { serveStdioIpc } from "./api/stdio-ipc.js";
import { environment } from "./config/environment.js";

function startHttpDiagnosticServer(): void {
  const server = createServer((request, response) => {
    try {
      route(request, response);
    } catch {
      console.error("Unhandled diagnostic request error.");
      if (!response.headersSent) {
        response.writeHead(500, {
          "content-type": "application/json; charset=utf-8",
          "cache-control": "no-store"
        });
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
    console.error("HTTP diagnostic server failed", error);
    process.exitCode = 1;
  });

  server.on("clientError", (_error, socket) => {
    socket.end("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n");
  });

  server.listen(environment.port, environment.host, () => {
    console.error(`${environment.serviceName} diagnostic endpoint listening on http://${environment.host}:${environment.port}`);
  });

  let shuttingDown = false;
  function shutdown(signal: string): void {
    if (shuttingDown) return;
    shuttingDown = true;
    console.error(`Received ${signal}; shutting down diagnostic HTTP server.`);
    const timeout = setTimeout(() => {
      console.error("Graceful HTTP diagnostic shutdown timed out.");
      process.exitCode = 1;
      server.closeAllConnections();
      server.close();
    }, 10_000);
    timeout.unref();
    server.close((error) => {
      clearTimeout(timeout);
      if (error) {
        console.error("HTTP diagnostic server shutdown failed", error);
        process.exitCode = 1;
      }
    });
  }

  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
}

const transportArgument = process.argv.find((argument) => argument.startsWith("--transport="));
const transport = transportArgument?.slice("--transport=".length) ?? "http";

if (transport === "stdio") {
  void serveStdioIpc(process.stdin, process.stdout)
    .then(() => {
      process.stdin.destroy();
    })
    .catch(() => {
      console.error("Local IPC runtime failed.");
      process.exitCode = 1;
      process.stdin.destroy();
    });
} else if (transport === "http") {
  startHttpDiagnosticServer();
} else {
  console.error("Unsupported backend transport mode.");
  process.exitCode = 1;
}
