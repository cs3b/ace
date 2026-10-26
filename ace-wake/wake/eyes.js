import { createHash } from "node:crypto";

const hash = (value) => createHash("sha256").update(JSON.stringify(value)).digest("hex");
export const EYES_ENTRY = "ace-wake-eyes";
export const defaults = { intervalSeconds: 30, maxEvents: 500, maxObservationsPerHour: 120, maxWakesPerHour: 20,
  timeoutMs: 10000, maxErrors: 3, maxPending: 2000, scope: "current", recipient: "self", syncRoutes: [] };

export function validateConfig(input) {
  if (!input || typeof input !== "object" || Array.isArray(input) ||
      Object.keys(input).some(key => !(key in defaults))) throw new Error("Invalid eyes configuration");
  const config = { ...defaults, ...input };
  for (const [key, min, max] of [["intervalSeconds", 1, 3600], ["maxEvents", 1, 2000],
    ["maxObservationsPerHour", 1, 3600], ["maxWakesPerHour", 1, 1000], ["timeoutMs", 100, 30000], ["maxErrors", 1, 10], ["maxPending", 1, 10000]]) {
    if (!Number.isInteger(config[key]) || config[key] < min || config[key] > max) throw new Error(`Invalid ${key}`);
  }
  if (typeof config.recipient !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(config.recipient)) throw new Error("Invalid observer recipient");
  if (!["current", "all"].includes(config.scope) || !Array.isArray(config.syncRoutes) || config.syncRoutes.length > 10 ||
      config.syncRoutes.some((p) => typeof p !== "string" || !p.startsWith("/"))) throw new Error("Invalid eyes sources");
  return config;
}

/** Observation/delivery bookkeeping in the existing Pi session, not a work
 * queue. It never starts tasks or accepts reports on behalf of their owner. */
export class Eyes {
  constructor({ snapshot, save, observe, deliver, now = Date.now, status = () => {}, deliveryStatus = () => "accepted", canDeliver = () => true }) {
    this.s = structuredClone(snapshot || { enabled: false, retired: false, config: defaults,
      pending: {}, acknowledged: {}, deadlines: {}, breaker: null, errors: 0, window: null });
    this.s.config = validateConfig(this.s.config);
    for (const key of ["pending", "acknowledged", "deadlines"])
      if (!this.s[key] || typeof this.s[key] !== "object" || Array.isArray(this.s[key])) throw new Error("Invalid persisted eyes state");
    if (typeof this.s.enabled !== "boolean" || typeof this.s.retired !== "boolean" ||
        !Number.isInteger(this.s.errors) || this.s.errors < 0) throw new Error("Invalid persisted eyes state");
    this.save = save; this.observe = observe; this.deliver = deliver; this.now = now; this.status = status;
    this.deliveryStatus = deliveryStatus; this.canDeliver = canDeliver;
    this.busy = false; this.disposed = false;
    // A process restart does not imply receipt acknowledgement. Reconcile the
    // same pending revisions; business-effect idempotence remains with .5.4.
    this.inflight = false;
    this.sent = new Map();
    this.generation = 0;
  }
  persist() { this.save(structuredClone(this.s)); this.status(this.summary()); }
  summary() { return { enabled: this.s.enabled, retired: this.s.retired, pending: Object.keys(this.s.pending).length,
    breaker: this.s.breaker, errors: this.s.errors, observations: this.s.window?.count || 0, wakes: this.s.window?.wakes || 0 }; }
  start(config) {
    if (this.s.retired) throw new Error("Retired actor cannot restart its eyes; hand off pending to its owner");
    if (this.s.breaker) throw new Error("Resolve breaker with explicit resume first");
    this.s.config = validateConfig(config); this.s.enabled = true; this.persist();
  }
  block(reason) {
    if (!this.s.breaker) { this.s.breaker = { reason, at: this.now() }; this.persist(); }
  }
  async resume() {
    if (this.s.retired) throw new Error("Retired actor cannot resume");
    // Explicit operator action; check source/transport readiness without a model
    // request. Quota availability must have been verified by the owner.
    const result = await this.observe(this.s.config);
    this.validate(result);
    this.s.breaker = null; this.s.errors = 0; this.s.window = null; this.inflight = false;
    this.s.enabled = true; this.persist();
    await this.tick();
  }
  retire() { this.generation++; this.s.enabled = false; this.s.retired = true; this.persist(); }
  dispose() { this.disposed = true; this.generation++; }
  quota(message) {
    if (/quota|insufficient.?(?:credit|balance)|billing.?limit|budget.?exceed|usage.?limit|rate.?limit|\b429\b/i.test(String(message))) this.block("quota-or-budget");
  }
  deadline(name, at, operationRevision) {
    if (!/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$/.test(name) || !Number.isSafeInteger(at) || at < 0 || typeof operationRevision !== "string" || !/^[a-zA-Z0-9._:-]{1,128}$/.test(operationRevision)) throw new Error("Invalid deadline");
    const key = `deadline:${name}`;
    delete this.s.pending[key];
    this.sent.delete(key); this.inflight = this.sent.size > 0;
    this.s.deadlines[name] = { at, operationRevision }; this.persist();
  }
  cancelDeadline(name) {
    delete this.s.deadlines[name]; delete this.s.pending[`deadline:${name}`];
    this.sent.delete(`deadline:${name}`); this.inflight = this.sent.size > 0; this.persist();
  }
  ack(key, revision) {
    if (this.s.pending[key]?.revision !== revision && this.sent.get(key) !== revision)
      throw new Error("Ack does not match an observed pending or delivered revision");
    this.s.acknowledged[key] = revision;
    if (this.s.pending[key]?.revision === revision) delete this.s.pending[key];
    this.sent.delete(key);
    this.inflight = this.sent.size > 0; this.persist();
  }
  validate(result) {
    if (result?.schema !== "ace.hitl.observation/v1" || !Array.isArray(result.events) || result.events.length > this.s.config.maxEvents)
      throw new Error("Invalid or over-budget HITL observation");
    if (result.settled !== undefined && !Array.isArray(result.settled)) throw new Error("Invalid settlement projection");
    const rows = [...result.events, ...(result.settled || [])];
    if (rows.length > this.s.config.maxEvents) throw new Error("Over-budget projection");
    const keys = new Set();
    for (const event of rows) {
      if (!/^[a-f0-9]{64}$/.test(event.key) || !/^[a-f0-9]{64}$/.test(event.revision) ||
          typeof event.id !== "string" || !/^[a-z0-9_-]{1,64}$/i.test(event.id) || keys.has(event.key)) throw new Error("Invalid event identity");
      keys.add(event.key);
    }
  }
  async tick() {
    if (this.busy || this.disposed || !this.s.enabled || this.s.retired || this.s.breaker) return;
    const now = this.now();
    if (!this.s.window || now - this.s.window.start >= 3600000) this.s.window = { start: now, count: 0, wakes: 0 };
    if (this.s.window.count >= this.s.config.maxObservationsPerHour) { this.block("observation-budget"); return; }
    this.s.window.count++; this.persist(); // Budget survives restart too.
    this.busy = true;
    const generation = this.generation;
    try {
      const result = await this.observe(this.s.config);
      if (generation !== this.generation || this.disposed) return;
      this.validate(result);
      for (const e of result.settled || []) {
        this.s.acknowledged[e.key] = e.revision;
        if (this.s.pending[e.key]?.revision === e.revision) delete this.s.pending[e.key];
        this.sent.delete(e.key);
      }
      if (this.inflight && this.sent.size === 0) this.inflight = false;
      for (const e of result.events) {
        if (this.s.acknowledged[e.key] !== e.revision) this.s.pending[e.key] = { id: e.id, revision: e.revision };
      }
      for (const [name, deadline] of Object.entries(this.s.deadlines)) {
        const { at, operationRevision } = deadline;
        const key = `deadline:${name}`, revision = hash([name, at, operationRevision]);
        if (now >= at && this.s.acknowledged[key] !== revision) this.s.pending[key] = { id: name, revision };
      }
      if (Object.keys(this.s.pending).length + Object.keys(this.s.acknowledged).length > this.s.config.maxPending) {
        this.block("retention-budget"); return;
      }
      this.persist();
      if (this.inflight && this.deliveryStatus() === "uncertain") {
        this.block("notification-unconfirmed"); return;
      }
      if (!this.inflight && !this.s.breaker && Object.keys(this.s.pending).length && this.canDeliver()) {
        // Retain identities before attempting delivery. A rejected send leaves
        // pending intact; acceptance by Pi is not application acknowledgement.
        if ((this.s.window.wakes || 0) >= this.s.config.maxWakesPerHour) { this.block("wake-budget"); return; }
        this.s.window.wakes = (this.s.window.wakes || 0) + 1;
        this.persist(); // Includes uncertain notification attempts, never token billing.
        const batch = Object.entries(this.s.pending).slice(0, 20);
        this.inflight = Boolean(await this.deliver(batch));
        if (this.inflight) this.sent = new Map(batch.map(([key, value]) => [key, value.revision]));
        if (!this.inflight) throw new Error("wake delivery refused");
      }
      if (this.s.errors && (!this.inflight || this.deliveryStatus() === "accepted")) { this.s.errors = 0; this.persist(); }
    } catch {
      this.s.errors++; this.persist();
      if (this.s.errors >= this.s.config.maxErrors) this.block("observation-or-delivery-failure");
    } finally { this.busy = false; }
  }
}
