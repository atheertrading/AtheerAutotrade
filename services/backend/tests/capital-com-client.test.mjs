import assert from "node:assert/strict";
import test from "node:test";
import {
  CapitalComApiError,
  CapitalComClient
} from "../dist/modules/broker-adapters/capital-com/capital-com-client.js";

function credentialsProvider() {
  return {
    async getCredentials() {
      return {
        identifier: "demo-user",
        apiKey: "test-api-key",
        apiKeyPassword: "test-api-password"
      };
    }
  };
}

function response(body, headers = {}, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      ...headers
    }
  });
}

test("session creation stores provider tokens in memory and uses demo endpoint", async () => {
  let request;
  const client = new CapitalComClient("demo", credentialsProvider(), async (url, init) => {
    request = { url, init };
    return response(
      { streamingHost: "wss://api-streaming-capital.backend-capital.com/" },
      { CST: "cst-test", "X-SECURITY-TOKEN": "security-test" }
    );
  });

  const session = await client.createSession();

  assert.equal(request.url, "https://demo-api-capital.backend-capital.com/api/v1/session");
  assert.equal(request.init.method, "POST");
  assert.equal(request.init.headers["X-CAP-API-KEY"], "test-api-key");
  assert.deepEqual(JSON.parse(request.init.body), {
    identifier: "demo-user",
    password: "test-api-password",
    encryptedPassword: false
  });
  assert.equal(session.cst, "cst-test");
  assert.equal(session.securityToken, "security-test");
  assert.equal(session.streamingHost, "wss://api-streaming-capital.backend-capital.com/");
  assert.equal(client.isAuthenticated, true);
});

test("historical prices require a session and use authenticated headers", async () => {
  const requests = [];
  const client = new CapitalComClient("demo", credentialsProvider(), async (url, init) => {
    requests.push({ url, init });
    if (init.method === "POST") {
      return response({}, { CST: "cst-test", "X-SECURITY-TOKEN": "security-test" });
    }
    return response({
      prices: [{
        snapshotTime: "2026-11-12T10:01:00",
        snapshotTimeUTC: "2026-11-12T08:01:00",
        openPrice: { bid: 100, ask: 101 },
        closePrice: { bid: 102, ask: 103 },
        highPrice: { bid: 104, ask: 105 },
        lowPrice: { bid: 99, ask: 100 }
      }],
      instrumentType: "COMMODITIES"
    });
  });

  await assert.rejects(
    client.getHistoricalPrices("OIL_CRUDE"),
    /session is not established/
  );
  await client.createSession();
  const result = await client.getHistoricalPrices("OIL_CRUDE", {
    resolution: "MINUTE_5",
    max: 50
  });

  assert.equal(result.prices.length, 1);
  assert.equal(result.prices[0].openPrice.bid, 100);
  assert.equal(result.instrumentType, "COMMODITIES");
  assert.match(requests[1].url, /\/api\/v1\/prices\/OIL_CRUDE\?/);
  assert.match(requests[1].url, /resolution=MINUTE_5/);
  assert.match(requests[1].url, /max=50/);
  assert.equal(requests[1].init.headers.CST, "cst-test");
  assert.equal(requests[1].init.headers["X-SECURITY-TOKEN"], "security-test");
});

test("historical price request rejects invalid ranges before network access", async () => {
  let requestCount = 0;
  const client = new CapitalComClient("demo", credentialsProvider(), async () => {
    requestCount += 1;
    return response({}, { CST: "cst-test", "X-SECURITY-TOKEN": "security-test" });
  });

  await client.createSession();
  await assert.rejects(
    client.getHistoricalPrices("OIL_CRUDE", { max: 1001 }),
    /max must be an integer/
  );
  await assert.rejects(
    client.getHistoricalPrices("OIL_CRUDE", {
      from: "2026-11-13T00:00:00",
      to: "2026-11-12T00:00:00"
    }),
    /from must not be later/
  );
  assert.equal(requestCount, 1);
});

test("unauthorized response invalidates the in-memory session", async () => {
  let authenticated = false;
  const client = new CapitalComClient("live", credentialsProvider(), async (url, init) => {
    if (init.method === "POST") {
      return response({}, { CST: "cst-test", "X-SECURITY-TOKEN": "security-test" });
    }
    authenticated = true;
    return response({ errorCode: "error.security.invalid-token" }, {}, 401);
  });

  await client.createSession();
  await assert.rejects(client.ping(), (error) => {
    assert.ok(error instanceof CapitalComApiError);
    assert.equal(error.status, 401);
    return true;
  });
  assert.equal(authenticated, true);
  assert.equal(client.isAuthenticated, false);
});

test("missing session tokens fail closed", async () => {
  const client = new CapitalComClient("demo", credentialsProvider(), async () => response({}));
  await assert.rejects(client.createSession(), /omitted CST/);
  assert.equal(client.isAuthenticated, false);
});

test("historical prices reject malformed OHLC bounds", async () => {
  const client = new CapitalComClient("demo", credentialsProvider(), async (url, init) => {
    if (init.method === "POST") {
      return response({}, { CST: "cst-test", "X-SECURITY-TOKEN": "security-test" });
    }
    return response({
      prices: [{
        snapshotTime: "2026-11-12T10:01:00",
        snapshotTimeUTC: "2026-11-12T08:01:00",
        openPrice: { bid: 100, ask: 101 },
        closePrice: { bid: 102, ask: 103 },
        highPrice: { bid: 99, ask: 98 },
        lowPrice: { bid: 98, ask: 99 }
      }]
    });
  });

  await client.createSession();
  await assert.rejects(
    client.getHistoricalPrices("OIL_CRUDE"),
    /invalid bid OHLC bounds/
  );
});
