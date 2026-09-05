# job-hell

Job listing scraper/research for a job pre-screen app — pull listings from
bot-protected job sites, filter into a list before applying.

## docs/

- `initial-research.md` — consensus of what is reachable per site, what is
  blocked, and what filters each site exposes. Plus deep-research corrections.
- `wellfound.md`, `linkedin.md`, `greenhouse.md`, `indeed.md`, `glassdoor.md`,
  `lever.md` — per-site deep research: exactly which extractors (embedded JSON,
  card schema, URL filters, pagination, endpoints) exist to build a filterable
  list. Each produced by Devin ACP primary pass + adversarial antagonize pass;
  every file ends with a VERDICT (and CORRECTION where the critique found an
  error).

## Stack

- Firecrawl (self-hosted v2.11.162, linux-mint:3002) — fast tier; works where
  no hard bot wall (Wellfound, LinkedIn, Greenhouse, Lever, Glassdoor SRCH).
- CamoFox (anti-detection browser, remote) — escalation tier for hard walls
  (Indeed SERP 403; Glassdoor per-job detail).
- Devin ACP (glm-5-2) for the deep-research passes — each site gets a primary
  extraction-research pass plus a second adversarial pass that re-runs every
  checkable claim against the live toolchain.

## Key extractor facts (see per-site docs)

- Best structured: **Lever** JSON API (`api.lever.co/v0/postings/<slug>?mode=json` +
  `department`/`location`/`commitment`/`team` server filters), **Greenhouse**
  legacy JSON API (`boards-api.greenhouse.io/v1/boards/<org>/jobs` — alive),
  **Wellfound** `__NEXT_DATA__` Apollo cache (Greenhouse embed also exposes a
  `__remixContext` blob).
- Hardest: **Indeed** (Firecrawl 403 → CamoFox a11y tree) and **Glassdoor**
  feed (fine) but detail page blocked on both tiers.
- Recurring pitfall: each site wraps its data in a different embedded JSON blob
  or card pattern — a per-site extractor is required, no single regex/endpoint
  works across all.