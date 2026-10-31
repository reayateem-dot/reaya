import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, beforeEach, test } from "node:test";
import { createLocalServer } from "../src/server.js";

let directory;
let server;
let baseUrl;
const token = "local-test-token";

beforeEach(async () => {
  directory = await mkdtemp(join(tmpdir(), "reaya-local-server-"));
});

afterEach(async () => {
  if (server?.listening) {
    await new Promise((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve()))
    );
  }
  server = undefined;
  await rm(directory, { recursive: true, force: true });
});

async function startServer(options = {}) {
  server = await createLocalServer({
    token,
    stateFile: join(directory, "data.json"),
    ...options
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
}

test("serves local services and persists favorite and medicine data", async () => {
  await startServer();

  const unauthorized = await fetch(`${baseUrl}/api/favorites`, {
    headers: { authorization: "Bearer wrong-token" }
  });
  assert.equal(unauthorized.status, 401);
  const localhostAccess = await fetch(`${baseUrl}/api/favorites`);
  assert.equal(localhostAccess.status, 200);

  const headers = {
    authorization: `Bearer ${token}`,
    "content-type": "application/json"
  };
  const services = await fetch(`${baseUrl}/api/services`, { headers });
  assert.equal(services.status, 200);
  assert.equal((await services.json()).services.length, 3);

  const medicine = {
    id: "med-1",
    name: "دواء تجريبي",
    dose: "قرص",
    times: ["08:00"],
    remaining: 5,
    totalQuantity: 10,
    notes: ""
  };
  const saved = await fetch(`${baseUrl}/api/medicines`, {
    method: "PUT",
    headers,
    body: JSON.stringify({ medicines: [medicine] })
  });
  assert.equal(saved.status, 200);

  await fetch(`${baseUrl}/api/favorites`, {
    method: "PUT",
    headers,
    body: JSON.stringify({ ids: ["doctor-1"] })
  });
  await new Promise((resolve) => server.close(resolve));

  server = await createLocalServer({
    token,
    stateFile: join(directory, "data.json")
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;

  const favorites = await fetch(`${baseUrl}/api/favorites`, { headers });
  assert.deepEqual(await favorites.json(), { ids: ["doctor-1"] });
  const medicines = await fetch(`${baseUrl}/api/medicines`, { headers });
  assert.deepEqual(await medicines.json(), { medicines: [medicine] });
});

test("sends validated conversations to Ollama", async () => {
  let sentPayload;
  await startServer({
    modelName: "test-model",
    fetchImpl: async (url, options) => {
      assert.equal(url, "http://ollama.test/api/chat");
      sentPayload = JSON.parse(options.body);
      return new Response(
        JSON.stringify({ message: { content: "إجابة محلية." } }),
        { status: 200 }
      );
    },
    chatUrl: "http://ollama.test/api/chat"
  });

  const response = await fetch(`${baseUrl}/api/chat`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({
      messages: [{ role: "user", text: "سؤال صحي" }]
    })
  });

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { text: "إجابة محلية." });
  assert.equal(sentPayload.model, "test-model");
  assert.equal(sentPayload.messages.at(-1).content, "سؤال صحي");
});

test("rejects malformed conversations and reports unavailable Ollama", async () => {
  await startServer({
    fetchImpl: async () => {
      throw new Error("Ollama is not running.");
    }
  });
  const headers = {
    authorization: `Bearer ${token}`,
    "content-type": "application/json"
  };

  const invalid = await fetch(`${baseUrl}/api/chat`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      messages: [{ role: "system", text: "not allowed" }]
    })
  });
  assert.equal(invalid.status, 400);

  const unavailable = await fetch(`${baseUrl}/api/chat`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      messages: [{ role: "user", text: "سؤال صحي" }]
    })
  });
  assert.equal(unavailable.status, 503);
  assert.match((await unavailable.json()).error, /Ollama/);
});
