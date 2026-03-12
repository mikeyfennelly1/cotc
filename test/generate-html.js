import { readFileSync, writeFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const report = JSON.parse(readFileSync(resolve(__dirname, "report.json"), "utf8"));

const { timestamp, duration, summary, suites } = report;

const suiteBlocks = suites.map((suite) => {
  const tests = suite.tests.map((t) => {
    const icon = t.status === "pass" ? "✔" : "✗";
    const cls = t.status === "pass" ? "pass" : "fail";
    const error = t.error
      ? `<div class="error">${escapeHtml(t.error)}</div>`
      : "";
    return `
      <div class="test ${cls}">
        <span class="icon">${icon}</span>
        <span class="name">${escapeHtml(t.name)}</span>
        <span class="duration">${t.duration}ms</span>
        ${error}
      </div>`;
  }).join("");

  const suiteStatus = suite.tests.some((t) => t.status === "fail") ? "fail" : "pass";
  return `
    <div class="suite ${suiteStatus}">
      <div class="suite-header">${escapeHtml(suite.name)}</div>
      <div class="suite-tests">${tests}</div>
    </div>`;
}).join("");

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

const passRate = summary.total > 0
  ? Math.round((summary.passed / summary.total) * 100)
  : 0;

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Test Report</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #0f1117;
      color: #e2e8f0;
      padding: 2rem;
      min-height: 100vh;
    }

    h1 { font-size: 1.5rem; font-weight: 600; margin-bottom: 0.25rem; }

    .meta {
      font-size: 0.8rem;
      color: #64748b;
      margin-bottom: 2rem;
    }

    .summary {
      display: flex;
      gap: 1rem;
      margin-bottom: 2rem;
      flex-wrap: wrap;
    }

    .stat {
      background: #1e2330;
      border-radius: 10px;
      padding: 1rem 1.5rem;
      min-width: 120px;
      text-align: center;
      border: 1px solid #2d3450;
    }

    .stat .value {
      font-size: 2rem;
      font-weight: 700;
      line-height: 1;
    }

    .stat .label {
      font-size: 0.75rem;
      color: #64748b;
      margin-top: 0.35rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .stat.passed .value { color: #22c55e; }
    .stat.failed .value { color: #ef4444; }
    .stat.total  .value { color: #94a3b8; }
    .stat.rate   .value { color: #3b82f6; }

    .progress {
      height: 6px;
      background: #1e2330;
      border-radius: 999px;
      margin-bottom: 2rem;
      overflow: hidden;
    }

    .progress-bar {
      height: 100%;
      border-radius: 999px;
      background: ${summary.failed > 0 ? "linear-gradient(90deg, #22c55e, #ef4444)" : "#22c55e"};
      width: ${passRate}%;
      transition: width 0.4s ease;
    }

    .suite {
      background: #1e2330;
      border: 1px solid #2d3450;
      border-radius: 10px;
      margin-bottom: 1rem;
      overflow: hidden;
    }

    .suite.fail { border-color: #7f1d1d; }

    .suite-header {
      padding: 0.75rem 1rem;
      font-weight: 600;
      font-size: 0.95rem;
      background: #252c3e;
      border-bottom: 1px solid #2d3450;
    }

    .suite.fail .suite-header {
      background: #2d1515;
      border-bottom-color: #7f1d1d;
    }

    .suite-tests { padding: 0.5rem 0; }

    .test {
      display: grid;
      grid-template-columns: 1.5rem 1fr auto;
      align-items: baseline;
      column-gap: 0.5rem;
      padding: 0.35rem 1rem;
      font-size: 0.875rem;
      row-gap: 0.2rem;
    }

    .test.fail { background: rgba(239, 68, 68, 0.06); }

    .icon { font-size: 0.8rem; }
    .test.pass .icon { color: #22c55e; }
    .test.fail .icon { color: #ef4444; }

    .name { color: #cbd5e1; }
    .test.fail .name { color: #fca5a5; }

    .duration { color: #475569; font-size: 0.75rem; white-space: nowrap; }

    .error {
      grid-column: 2 / -1;
      color: #f87171;
      font-size: 0.78rem;
      font-family: "SFMono-Regular", Consolas, monospace;
      background: rgba(239, 68, 68, 0.08);
      padding: 0.4rem 0.6rem;
      border-radius: 4px;
      border-left: 2px solid #ef4444;
      word-break: break-word;
    }
  </style>
</head>
<body>
  <h1>Test Report</h1>
  <p class="meta">
    Run at ${new Date(timestamp).toLocaleString()} &nbsp;·&nbsp; ${duration}ms total
  </p>

  <div class="summary">
    <div class="stat total">
      <div class="value">${summary.total}</div>
      <div class="label">Total</div>
    </div>
    <div class="stat passed">
      <div class="value">${summary.passed}</div>
      <div class="label">Passed</div>
    </div>
    <div class="stat failed">
      <div class="value">${summary.failed}</div>
      <div class="label">Failed</div>
    </div>
    <div class="stat rate">
      <div class="value">${passRate}%</div>
      <div class="label">Pass rate</div>
    </div>
  </div>

  <div class="progress">
    <div class="progress-bar"></div>
  </div>

  ${suiteBlocks}
</body>
</html>`;

writeFileSync(resolve(__dirname, "report.html"), html);
console.log(`Report written to test/report.html`);
