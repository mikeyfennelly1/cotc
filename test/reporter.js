/**
 * Custom Node test reporter.
 * Streams spec-like output to stdout and writes report.json on completion.
 */

import { writeFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default async function* reporter(source) {
  const results = {
    timestamp: new Date().toISOString(),
    duration: 0,
    summary: { total: 0, passed: 0, failed: 0 },
    suites: [],
  };

  const startTime = Date.now();

  // Keyed by nesting level → current suite at that depth
  const suiteByNesting = new Map();
  // Track the nesting level of the first test:start we see, to detect the suite depth
  let suiteNesting = null;

  function extractError(error) {
    if (!error) return null;
    if (typeof error === "string") return error;
    // Prefer the direct message (which is our custom err() string) over cause
    const msg = error.message || error.cause?.message || error.toString();
    // Also surface actual vs expected from AssertionError if the message is missing
    if (!msg && error.actual !== undefined) {
      return `got ${JSON.stringify(error.actual)}, expected ${JSON.stringify(error.expected)}`;
    }
    return msg || JSON.stringify(error);
  }

  for await (const event of source) {
    const { type, data } = event;

    if (type === "test:start") {
      // The first test:start nesting level we see is always a suite (describe block).
      // Node may wrap files in an implicit root, so we detect dynamically.
      if (suiteNesting === null) suiteNesting = data.nesting;

      if (data.nesting === suiteNesting) {
        const suite = { name: data.name, tests: [] };
        results.suites.push(suite);
        suiteByNesting.set(data.nesting, suite);
        yield `\n${data.name}\n`;
      }
    }

    if (type === "test:pass") {
      if (data.nesting === suiteNesting) continue; // suite completed
      const suite = suiteByNesting.get(suiteNesting);
      const duration = Math.round(data.details?.duration ?? 0);
      suite?.tests.push({ name: data.name, status: "pass", duration });
      results.summary.total++;
      results.summary.passed++;
      yield `  ✔ ${data.name} (${duration}ms)\n`;
    }

    if (type === "test:fail") {
      if (data.nesting === suiteNesting) continue; // suite completed
      const suite = suiteByNesting.get(suiteNesting);
      const duration = Math.round(data.details?.duration ?? 0);
      const errorMsg = extractError(data.details?.error);
      suite?.tests.push({ name: data.name, status: "fail", duration, error: errorMsg });
      results.summary.total++;
      results.summary.failed++;
      yield `  ✗ ${data.name} (${duration}ms)\n    ${errorMsg}\n`;
    }
  }

  results.duration = Date.now() - startTime;

  const { total, passed, failed } = results.summary;
  yield `\n${passed}/${total} passed${failed > 0 ? `, ${failed} failed` : ""} (${results.duration}ms)\n`;

  writeFileSync(resolve(__dirname, "report.json"), JSON.stringify(results, null, 2));
}
