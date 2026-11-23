# Input: {results: [...], passed, requests, quota, fail_on, min_grade}. Output: Markdown for $GITHUB_STEP_SUMMARY.
# cell: untrusted text for a Markdown table cell. HTML specials and backticks become entities, | is escaped,
# newlines become spaces. Code is written as <code>, never as a backtick span, so nothing can close it early.
def cell: tostring | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;") | gsub("`"; "&#96;")
  | gsub("\\|"; "\\|") | gsub("\r?\n|\r"; " ");
def code: "<code>\(cell)</code>";
def num: if type == "number" then . else 0 end;
def link($text): if (. | type) == "string" and test("^https://[^\\s()<>\\[\\]]*$") then "[\($text | cell)](\(.))" else ($text | cell) end;
def icon: if . then "✅" else "❌" end;
def sev: {high: "🔴 high", medium: "🟠 medium", low: "🟡 low", info: "⚪ info"}[.] // .;

([.results[] | select(.report)]) as $ok
| ([.results[] | select(.report | not)]) as $other
| "## Shipshape \(.passed | icon)\n",
  "Fail on: \(.fail_on | code)\(if .min_grade != "" then " · minimum grade: \(.min_grade | code)" else "" end)"
  + " · requests used: \(.requests)\(if .quota != "" then " · quota left this month: \(.quota)" else "" end)",
  "",
  (if ($ok | length) > 0 then
    "| File | Grade | Score | High | Medium | Low | Info | Passed |",
    "|---|---|---|---|---|---|---|---|",
    ($ok[] | "| \(.file | code) | \(.report.grade | cell) | \(.report.score | cell) | \(.report.summary.high | num) | \(.report.summary.medium | num) | \(.report.summary.low | num) | \(.report.summary.info | num) | \(.passed | icon) |"),
    "",
    ($ok[] | select((.report.findings | length) > 0)
      | "<details><summary>\(.file | code): \(.report.findings | length) findings</summary>",
        "",
        "| Severity | Rule | Line | Finding | Fix |",
        "|---|---|---|---|---|",
        (.report.findings[] | "| \(.severity | sev) | \(. as $f | $f.url // "" | link($f.id)) | \(if (.line | type) == "number" then .line | floor else "" end) | \(.title | cell) | \(.fix // "" | cell) |"),
        "",
        "</details>",
        "")
  else "No Dockerfile or Kubernetes manifest was analysed.\n" end),
  (if ($other | length) > 0 then
    "### Not analysed",
    "",
    "| File | Why |",
    "|---|---|",
    ($other[] | "| \(.file | code) | \(.reason | cell) |"),
    ""
  else empty end)
