import assert from "node:assert/strict";
import test from "node:test";
import { route } from "../dist/api/router.js";

function invokeRoute(method, url) {
  const request = { method, url };
  const response = {
    statusCode: undefined,
    headers: undefined,
    body: "",
    writeHead(statusCode, headers) {
      this.statusCode = statusCode;
      this.headers = headers;
      return this;
    },
    end(body = "") {
      this.body = body;
      return this;
    }
  };
  route(request, response);
  return response;
}

test("GET /health reports service health without trading claims", () => {
  const response = invokeRoute("GET", "/health");
  assert.equal(response.statusCode, 200);
  assert.ok(response.headers["content-type"].includes("application/json"));
  const body = JSON.parse(response.body);
  assert.equal(body.service, "atheerautotrade-backend");
  assert.equal(body.status, "healthy");
  assert.equal(body.version, "0.1.0");
  assert.ok(Number.isFinite(Date.parse(body.timestamp)));
  assert.equal("brokerConnected" in body, false);
  assert.equal("tradingOperational" in body, false);
});

test("unknown paths return a structured not-found response", () => {
  const response = invokeRoute("GET", "/missing");
  assert.equal(response.statusCode, 404);
  assert.equal(JSON.parse(response.body).error.code, "NOT_FOUND");
});
