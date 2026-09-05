#!/bin/bash
# job-hell stacked research runner - batch 2 (7 new sites).
# Each site: one glm-run.sh = Devin ACP PRIMARY + ANTAGONIZE + caveman.
# Sequential (ACP cannot run parallel). Writes into docs/<site>.md.
set -u
GLM=~/hermes-tools/scripts/glm-run.sh
REPO=/Users/pastry/Projects/job-hell
DOCS="$REPO/docs"
LOG_DIR="$DOCS/.runs-logs"
ART="$DOCS/.runs-artifacts"
CTX="$DOCS/initial-research.md"
mkdir -p "$LOG_DIR" "$ART"

# bash-3.2 safe: parallel arrays via indexed loop
NAMES=(workatastartup ziprecruiter levelsfyi remoteok weworkremotely builtin otta)
URLS=(
  "https://www.workatastartup.com/companies"
  "https://www.ziprecruiter.com/jobs?q=react+native"
  "https://www.levels.fyi/jobs"
  "https://remoteok.com/remote-dev-jobs"
  "https://weworkremotely.com/categories/remote-programming-jobs"
  "https://builtin.com/jobs?search=react%20native"
  "https://ac.otta.com/jobs"
)

task_for() {
  local name="$1" url="$2"
  cat <<EOF
Deep-research the job site $name (URL: $url) for job-hell, a job pre-screen
app. Goal: find what EXTRACTORS are available to pull a FILTERABLE job list.

You have a live browser/scrape toolchain wired as MCP tools:
- firecrawl_scrape / firecrawl_map / firecrawl_search / firecrawl_health
  (self-hosted Firecrawl; HTTP 200 != success, read metadata.statusCode)
- camofox_open / camofox_navigate / camofox_snapshot / camofox_click /
  camofox_links (anti-detection browser; snapshot returns an accessibility tree)
Prefer Firecrawl first; escalate to CamoFox when Firecrawl 403s or returns only
a landing/auth shell. You may also run the CLIs directly:
  ~/hermes-tools/tools/firecrawl/scripts/firecrawl.sh scrape|map|search <url>
  ~/hermes-tools/bin/camofox.sh --backend remote open <url> ; ... snapshot
Also probe for a PUBLIC JSON API (many job boards ship one): common patterns are
/api, /jobs.json, /api/v1/jobs, /api/jobs?q=, /search.json, ?format=json,
__NEXT_DATA__ / __remixContext / window.<config> blobs in the HTML.

Actually FETCH the site live. Do not fabricate. Do not just reason about it.

Investigate and document concretely:
1. Public endpoints / embedded JSON / data API surface the site uses to serve
   listings (note any JSON blobs, next-data, graph endpoints, or per-job APIs).
2. The listing-card structure in the fetched markdown (Firecrawl) or
   accessibility tree (CamoFox) - give the real selector/heading/text pattern
   you observed.
3. Which fields are directly extractable: title, company, location, salary,
   remote flag, posted date, apply URL, job id. State which are present vs absent.
4. Filters the site's search UI exposes (remote, job type, experience, pay,
   date posted, skills, location) - and whether they are usable via URL params
   or only after JS interaction / auth.
5. Blocks / bot walls / auth gates, and which tier actually got through
   (Firecrawl vs CamoFox). Does it require signup/login to browse?
6. Pagination / next-page behavior (is page 2 reachable? how?).
7. Anything the OWNERS have blocked: robots.txt disallow rules, auth walls,
   API rate limits, legal/ToS note.

STARTING CONTEXT is docs/initial-research.md - the consensus of other sites
tested. This site is NEW to the set; there is no prior finding for it.

OUTPUT FORMAT (this exact markdown, returned as your final message):
---
# $name - Deep Research: extractors for a filterable job list

## Method (what I actually fetched)
...

## Accessibility / blockers
...

## Data surface (endpoints / JSON / API)
...

## Extractable fields
- title: ...   company: ...   location: ...   salary: ...   remote: ...
- posted date: ...   apply url: ...   job id: ...

## Filters available
...

## Pagination
...

## Verified against (evidence)
(list exact URLs fetched and status/statusCode you saw)
---
Write the full markdown report as your response. Facts only from real fetches.
If something is blocked, say so plainly rather than guessing.
EOF
}

declare -a summary=()
i=0
for name in "${NAMES[@]}"; do
  url="${URLS[$i]}"
  out="$DOCS/$name.md"
  log="$LOG_DIR/$name.run.json"
  task="$(task_for "$name" "$url")"
  echo "===== RUN [$name] $(date +%H:%M:%S) ====="
  "$GLM" --task "$task" --context "$CTX" --model glm-5-2 \
    --cwd "$REPO" --out "$out" --log "$log" --artifacts "$ART/$name" \
    2>"$LOG_DIR/$name.stderr.log"
  rc=$?
  verdict=$(jq -r '.final_verdict // "?"' "$log" 2>/dev/null)
  echo "[$name] rc=$rc verdict=$verdict out_bytes=$(wc -c < "$out" 2>/dev/null)"
  summary+=("$name rc=$rc verdict=$verdict")
  i=$((i+1))
done

echo
echo "=========== STACK SUMMARY ==========="
for s in "${summary[@]}"; do echo "  $s"; done
echo "ALL DONE $(date +%H:%M:%S)"