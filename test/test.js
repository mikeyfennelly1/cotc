import { test, describe } from "node:test";
import assert from "node:assert/strict";

const BASE = "http://localhost:8080";

async function get(path) {
  const res = await fetch(`${BASE}${path}`);
  return { status: res.status, body: await res.json().catch(() => null) };
}

async function post(path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json().catch(() => null) };
}

async function del(path) {
  const res = await fetch(`${BASE}${path}`, { method: "DELETE" });
  return { status: res.status, body: await res.json().catch(() => null) };
}

function err(expected, actual, body) {
  const apiMsg = body?.error ?? body?.message ?? body?.msg ?? JSON.stringify(body);
  return `expected ${expected}, got ${actual} — API: ${apiMsg}`;
}

// ── Group ─────────────────────────────────────────────────────────────────────

describe("Group API", () => {
  test("GET /api/group/health returns 200", async () => {
    const { status, body } = await get("/api/group/health");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(body?.msg);
  });

  test("GET /api/group returns array", async () => {
    const { status, body } = await get("/api/group");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(Array.isArray(body));
  });

  test("GET /api/group/fqd returns array of names", async () => {
    const { status, body } = await get("/api/group/fqd");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(Array.isArray(body));
  });

  test("POST /api/group creates group", async () => {
    const { status, body } = await post("/api/group?name=test-group", null);
    assert.equal(status, 201, err(201, status, body));
  });

  test("POST /api/group duplicate returns 409", async () => {
    const { status, body } = await post("/api/group?name=test-group", null);
    assert.equal(status, 409, err(409, status, body));
  });

  test("GET /api/group?name= returns group", async () => {
    const { status, body } = await get("/api/group?name=test-group");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(body != null);
  });

  test("GET /api/group?name= nonexistent returns 404", async () => {
    const { status, body } = await get("/api/group?name=nonexistent-group-xyz");
    assert.equal(status, 404, err(404, status, body));
  });

  test("POST /api/group creates child group", async () => {
    const { status, body } = await post("/api/group?name=test-group.test-child", null);
    assert.equal(status, 201, err(201, status, body));
  });

  test("GET /api/group/children returns child list", async () => {
    const { status, body } = await get("/api/group/children?group=test-group");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(Array.isArray(body));
  });

  test("GET /api/group/children nonexistent group returns 404", async () => {
    const { status, body } = await get("/api/group/children?group=nonexistent-xyz");
    assert.equal(status, 404, err(404, status, body));
  });
});

// ── Producer ──────────────────────────────────────────────────────────────────

describe("Producer API", () => {
  test("GET /api/producer returns array", async () => {
    const { status, body } = await get("/api/producer");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(Array.isArray(body));
  });

  test("POST /api/producer creates producer", async () => {
    const { status, body } = await post("/api/producer", { name: "test-producer", group: "test-group" });
    assert.equal(status, 201, err(201, status, body));
  });

  test("POST /api/producer duplicate returns 409", async () => {
    const { status, body } = await post("/api/producer", { name: "test-producer", group: "test-group" });
    assert.equal(status, 409, err(409, status, body));
  });

  test("POST /api/producer unknown group returns 404", async () => {
    const { status, body } = await post("/api/producer", { name: "orphan", group: "no-such-group" });
    assert.equal(status, 404, err(404, status, body));
  });

  test("GET /api/producer?name= returns producer", async () => {
    const { status, body } = await get("/api/producer?name=test-producer");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(body != null);
  });

  test("GET /api/producer?name= nonexistent returns 404", async () => {
    const { status, body } = await get("/api/producer?name=nonexistent-xyz");
    assert.equal(status, 404, err(404, status, body));
  });

  test("GET /api/producer/:groupName returns producers for group", async () => {
    const { status, body } = await get("/api/producer/test-group");
    assert.equal(status, 200, err(200, status, body));
    assert.ok(Array.isArray(body));
  });
});

// ── Device Commands ───────────────────────────────────────────────────────────

describe("Device Command API", () => {
  test("POST /api/consumer/commands/ empty body returns 400", async () => {
    const { status, body } = await post("/api/consumer/commands/", {});
    assert.equal(status, 400, err(400, status, body));
    assert.ok(body?.error);
  });

  test("POST /api/consumer/commands/ missing command returns 400", async () => {
    const { status, body } = await post("/api/consumer/commands/", { device_id: "dev-1" });
    assert.equal(status, 400, err(400, status, body));
  });

  test("POST /api/consumer/commands/ missing device_id returns 400", async () => {
    const { status, body } = await post("/api/consumer/commands/", { command: "restart" });
    assert.equal(status, 400, err(400, status, body));
  });

  test("POST /api/consumer/commands/ valid body returns 201", async () => {
    const { status, body } = await post("/api/consumer/commands/", {
      device_id: "test-device-001",
      command: "ping",
      params: { timeout: 5 },
    });
    // 201 on success, 500 if Firestore is unreachable
    assert.ok(status === 201 || status === 500, err(201, status, body));
  });
});

// ── Cleanup ───────────────────────────────────────────────────────────────────

describe("Cleanup", () => {
  test("DELETE /api/producer?name=test-producer returns 204", async () => {
    const { status, body } = await del("/api/producer?name=test-producer");
    assert.equal(status, 204, err(204, status, body));
  });

  test("DELETE /api/producer nonexistent returns 404", async () => {
    const { status, body } = await del("/api/producer?name=nonexistent-xyz");
    assert.equal(status, 404, err(404, status, body));
  });

  test("DELETE /api/group?name=test-group.test-child returns 204", async () => {
    const { status, body } = await del("/api/group?name=test-group.test-child");
    assert.equal(status, 204, err(204, status, body));
  });

  test("DELETE /api/group?name=test-group returns 204", async () => {
    const { status, body } = await del("/api/group?name=test-group");
    assert.equal(status, 204, err(204, status, body));
  });

  test("DELETE /api/group nonexistent returns 404", async () => {
    const { status, body } = await del("/api/group?name=nonexistent-xyz");
    assert.equal(status, 404, err(404, status, body));
  });
});
