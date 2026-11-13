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
      {
        streamingHost: "wss://api-streaming-capital.backend-capital.com/",
        currentAccountId: "demo-account-1"
      },
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
  assert.equal(session.activeAccountId, "demo-account-1");
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


test("read-only account, preferences, positions, and working orders use authenticated GET endpoints", async () => {
  const requests=[];
  const client=new CapitalComClient("demo",credentialsProvider(),async(url,init)=>{
    requests.push({url,init});
    if(init.method==="POST") return response({}, {CST:"cst-test","X-SECURITY-TOKEN":"security-test"});
    if(url.endsWith("/api/v1/accounts")) return response({accounts:[{accountId:"demo-account-1",accountName:"USD",status:"ENABLED",accountType:"CFD",preferred:true,currency:"USD",symbol:"$",balance:{balance:1000,deposit:950,profitLoss:50,available:800}}]});
    if(url.endsWith("/api/v1/accounts/preferences")) return response({hedgingMode:false,leverages:{COMMODITIES:{current:5,available:[1,2,5,10]}}});
    if(url.endsWith("/api/v1/positions")) return response({positions:[{position:{dealId:"position-1",dealReference:"p-reference-1",size:2,direction:"BUY",level:75.5,currency:"USD",leverage:5,upl:12.5,createdDateUTC:"2026-11-13T10:00:00.000",guaranteedStop:false},market:{epic:"OIL_CRUDE",instrumentName:"Crude Oil",instrumentType:"COMMODITIES",marketStatus:"TRADEABLE",bid:75.4,offer:75.6,lotSize:1,updateTimeUTC:"2026-11-13T10:01:00.000"}}]});
    if(url.endsWith("/api/v1/workingorders")) return response({workingOrders:[{workingOrderData:{dealId:"working-order-1",direction:"SELL",epic:"OIL_CRUDE",orderSize:1,orderLevel:80,orderType:"LIMIT",timeInForce:"GOOD_TILL_CANCELLED",currencyCode:"USD",leverage:5,guaranteedStop:false},marketData:{epic:"OIL_CRUDE",instrumentName:"Crude Oil",instrumentType:"COMMODITIES",marketStatus:"TRADEABLE",bid:75.4,offer:75.6}}]});
    throw new Error("Unexpected endpoint: "+url);
  });
  await client.createSession();
  const accounts=await client.getAccounts(), prefs=await client.getAccountPreferences();
  const positions=await client.getPositions(), orders=await client.getWorkingOrders();
  assert.equal(accounts.accounts[0].balance.available,800);
  assert.equal(accounts.activeAccountId,"demo-account-1");
  assert.equal(prefs.hedgingMode,false);
  assert.deepEqual(prefs.leverages.COMMODITIES.available,[1,2,5,10]);
  assert.equal(positions.positions[0].position.direction,"BUY");
  assert.equal(positions.positions[0].market.epic,"OIL_CRUDE");
  assert.equal(orders.workingOrders[0].workingOrderData.direction,"SELL");
  assert.equal(orders.workingOrders[0].workingOrderData.orderType,"LIMIT");
  assert.ok(accounts.observedAt&&positions.observedAt&&orders.observedAt);
  assert.deepEqual(requests.slice(1).map(x=>new URL(x.url).pathname),["/api/v1/accounts","/api/v1/accounts/preferences","/api/v1/positions","/api/v1/workingorders"]);
  for(const x of requests.slice(1)){assert.equal(x.init.method,"GET");assert.equal(x.init.headers.CST,"cst-test");assert.equal(x.init.headers["X-SECURITY-TOKEN"],"security-test");}
});

test("account snapshot parser rejects missing broker balance fields", async () => {
  const client=new CapitalComClient("demo",credentialsProvider(),async(url,init)=>{
    if(init.method==="POST") return response({}, {CST:"cst-test","X-SECURITY-TOKEN":"security-test"});
    return response({accounts:[{accountId:"a",accountName:"USD",status:"ENABLED",accountType:"CFD",preferred:true,currency:"USD",symbol:"$",balance:{balance:1000,deposit:950,profitLoss:50}}]});
  });
  await client.createSession();
  await assert.rejects(client.getAccounts(),/account.balance.available/);
});
