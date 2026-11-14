import assert from "node:assert/strict";
import test from "node:test";
import {
  CapitalComApiError,
  CapitalComClient,
  CapitalComSubmissionUnknownError
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
    headers: { "content-type": "application/json", ...headers }
  });
}

async function connectedClient(fetcher) {
  const client = new CapitalComClient("demo", credentialsProvider(), fetcher);
  await client.createSession();
  return client;
}

test("market position submission sends the documented authenticated POST payload", async () => {
  const requests = [];
  const client = await connectedClient(async (url, init) => {
    requests.push({ url, init });
    if (init.method === "POST" && url.endsWith("/api/v1/session")) {
      return response({}, { CST: "cst-demo", "X-SECURITY-TOKEN": "security-demo" });
    }
    return response({ dealReference: "o_demo-reference" });
  });

  const result = await client.createPosition({
    epic: "OIL_CRUDE",
    direction: "BUY",
    size: 0.5,
    stopLevel: 72.25,
    profitLevel: 76.5
  });

  const submission = requests.at(-1);
  assert.equal(submission.url, "https://demo-api-capital.backend-capital.com/api/v1/positions");
  assert.equal(submission.init.method, "POST");
  assert.equal(submission.init.headers.CST, "cst-demo");
  assert.equal(submission.init.headers["X-SECURITY-TOKEN"], "security-demo");
  assert.equal(submission.init.headers["content-type"], "application/json");
  assert.deepEqual(JSON.parse(submission.init.body), {
    epic: "OIL_CRUDE",
    direction: "BUY",
    size: 0.5,
    stopLevel: 72.25,
    profitLevel: 76.5
  });
  assert.deepEqual(result, { dealReference: "o_demo-reference" });
});

test("market position submission validates the request before network access", async () => {
  let calls = 0;
  const client = await connectedClient(async (url, init) => {
    calls += 1;
    if (init.method === "POST" && url.endsWith("/api/v1/session")) {
      return response({}, { CST: "cst-demo", "X-SECURITY-TOKEN": "security-demo" });
    }
    return response({ dealReference: "unexpected" });
  });
  const afterConnect = calls;

  await assert.rejects(
    client.createPosition({ epic: "OIL_CRUDE", direction: "HOLD", size: 1, stopLevel: 70 }),
    /direction must be BUY or SELL/
  );
  await assert.rejects(
    client.createPosition({ epic: "OIL_CRUDE", direction: "BUY", size: 0, stopLevel: 70 }),
    /size must be a positive/
  );
  await assert.rejects(
    client.createPosition({ epic: "OIL_CRUDE", direction: "BUY", size: 1, stopLevel: 0 }),
    /stopLevel must be a positive/
  );
  assert.equal(calls, afterConnect);
});

test("ambiguous transport failure is surfaced as unknown and never retried", async () => {
  let submissions = 0;
  const client = await connectedClient(async (url, init) => {
    if (url.endsWith("/api/v1/session")) {
      return response({}, { CST: "cst-demo", "X-SECURITY-TOKEN": "security-demo" });
    }
    if (init.method === "POST") {
      submissions += 1;
      throw new Error("socket closed after request write");
    }
    throw new Error("unexpected request");
  });

  await assert.rejects(
    client.createPosition({ epic: "OIL_CRUDE", direction: "SELL", size: 1, stopLevel: 80 }),
    (error) => error instanceof CapitalComSubmissionUnknownError
      && /reconciliation is required/.test(error.message)
  );
  assert.equal(submissions, 1);
});

test("broker 4xx rejection remains a definitive API error", async () => {
  const client = await connectedClient(async (url, init) => {
    if (url.endsWith("/api/v1/session")) {
      return response({}, { CST: "cst-demo", "X-SECURITY-TOKEN": "security-demo" });
    }
    return response({ errorCode: "error.invalid.size" }, {}, 400);
  });

  await assert.rejects(
    client.createPosition({ epic: "OIL_CRUDE", direction: "BUY", size: 1, stopLevel: 70 }),
    (error) => error instanceof CapitalComApiError && error.status === 400
  );
});

test("HTTP 5xx and malformed success responses are treated as unknown outcomes", async (t) => {
  for (const scenario of [
    { name: "server error", reply: () => response({ errorCode: "temporary" }, {}, 503) },
    { name: "missing deal reference", reply: () => response({}) },
    { name: "invalid JSON", reply: () => new Response("not-json", { status: 200 }) }
  ]) {
    await t.test(scenario.name, async () => {
      const client = await connectedClient(async (url) => {
        if (url.endsWith("/api/v1/session")) {
          return response({}, { CST: "cst-demo", "X-SECURITY-TOKEN": "security-demo" });
        }
        return scenario.reply();
      });
      await assert.rejects(
        client.createPosition({ epic: "OIL_CRUDE", direction: "BUY", size: 1, stopLevel: 70 }),
        CapitalComSubmissionUnknownError
      );
    });
  }
});

test("market position submission rejects a missing session before network access", async () => {
  let calls = 0;
  const client = new CapitalComClient("demo", credentialsProvider(), async () => {
    calls += 1;
    return response({ dealReference: "unexpected" });
  });

  await assert.rejects(
    client.createPosition({ epic: "OIL_CRUDE", direction: "BUY", size: 1, stopLevel: 70 }),
    /session is not established/
  );
  assert.equal(calls, 0);
});

test("LIVE dealing is disabled even when a live REST client is constructed", async () => {
  let submissions = 0;
  const client = new CapitalComClient("live", credentialsProvider(), async (url, init) => {
    if (url.endsWith("/api/v1/session")) {
      return response({}, { CST: "cst-live", "X-SECURITY-TOKEN": "security-live" });
    }
    submissions += 1;
    return response({ dealReference: "must-not-be-created" });
  });
  await client.createSession();

  await assert.rejects(
    client.createPosition({ epic: "OIL_CRUDE", direction: "BUY", size: 1, stopLevel: 70 }),
    /LIVE dealing is disabled/
  );
  assert.equal(submissions, 0);
});

test("deal confirmation parses broker status and affected deals", async () => {
  const requests = [];
  const client = await connectedClient(async (url, init) => {
    requests.push({ url, init });
    if (url.endsWith("/api/v1/session")) {
      return response({}, { CST: "cst-demo", "X-SECURITY-TOKEN": "security-demo" });
    }
    return response({
      date: "2026-11-14T09:30:00.000",
      status: "OPEN",
      dealStatus: "ACCEPTED",
      dealReference: "o_demo-reference",
      dealId: "deal-1",
      affectedDeals: [{ dealId: "deal-1", status: "OPENED" }],
      level: 74.12,
      size: 0.5,
      direction: "BUY"
    });
  });

  const confirmation = await client.getDealConfirmation("o_demo-reference");
  assert.equal(requests.at(-1).url, "https://demo-api-capital.backend-capital.com/api/v1/confirms/o_demo-reference");
  assert.equal(requests.at(-1).init.method, "GET");
  assert.equal(confirmation.status, "OPEN");
  assert.equal(confirmation.dealStatus, "ACCEPTED");
  assert.equal(confirmation.affectedDeals[0].status, "OPENED");
  assert.equal(confirmation.level, 74.12);
  assert.equal(confirmation.direction, "BUY");
});
