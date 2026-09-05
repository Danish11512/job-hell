# job-hell — Initial Research

Consensus of what is reachable per job site, what is blocked, and what
filters/fields each site exposes. Basis: live scrape experiment (2026-09-04)
via self-hosted Firecrawl v2.11.162 (linux-mint:100.121.96.42:3002) and
CamoFox anti-detection browser (remote). Every claim below came from real
execution (raw responses + re-runs + parser attempts), not inference.

## Stack note

Two-tier fetch model:

- Firecrawl (fast, server-side render + proxy) — works where no hard bot wall.
- CamoFox (real browser fingerprint spoof, remote Docker) — escalation tier for
  sites that 403 or only render a login/landing shell.

Rule learned: Firecrawl HTTP 200 does NOT mean success. Glassdoor returned 200
with only a landing shell. Always validate against real job fields
(title / company / location / salary / apply URL), not the status code.

---

## Per-site consensus

### 1. Wellfound (wellfound.com)

- Reachability: REACHABLE via Firecrawl. No bot wall observed. Stable across
  re-runs (sc=200, ~30K chars both runs).
- Accessible: full job cards — title, company, location(s), salary range,
  remote/in-office flag, equity note, posted age, deep apply URL.
- Not accessible / blocked: none observed at listing level. Pagination page-2
  unverified (page 1 only).
- Fields/filters available in data: salary range ($Xk–$Yk), remote flag
  (Remote only / In office / Hybrid), location, equity, role category, posting
  age (today / yesterday / N days / N weeks), company, apply URL.
- Parse: clean once the card pattern is known (33 unique cards parsed).
  Markdown is indented/nested with interleaved logo-image links — needs a
  per-site extractor, not one generic regex.

### 2. LinkedIn (linkedin.com/jobs)

- Reachability: REACHABLE via Firecrawl as guest (search listings 200).
  Stable across re-runs (~30K chars).
- Accessible: listing cards — title, company, location, posting age, "Actively
  Hiring" badge, deep apply URL (jobs/view/<slug>).
- Not accessible: salary is effectively absent from the listings feed; full
  posting body / easy-apply payload requires auth. Feed is stale-heavy (many
  posts 1–10 months old; only ~3 new per page).
- Fields/filters: keyword, location, date-filter implied by posting age,
  company, apply URL. NOT usefully filterable by salary at the feed layer.
- Parse caveat: needs title dedup (120 postings / 95 unique titles in sample)
  and a recency filter to be useful for "apply before it closes".

### 3. Greenhouse (boards.greenhouse.io)

- Reachability: REACHABLE via Firecrawl. No bot wall. Cleanest output of all —
  one row per job ($job | title | location | url?gh_jid=N).
- Accessible: title, location, job-board URL with gh_jid (stable apply ID),
  department/category groupings (e.g. Engineering & Technology, Software
  Engineering). 50 rows parsed in sample.
- Not accessible: no salary in the board feed. No aggregated filters exposed by
  the embed; each board has its own category/department grouping.
- Fields/filters: !skllsal / location, department, job ID (gh_jid), URL.

### 4. Indeed (indeed.com)

- Reachability: BLOCKED on Firecrawl (403 Forbidden, stable). REACHABLE via
  CamoFox — renders real structured cards.
- Accessible (via CamoFox tree): title, company, location, description snippet,
  per-job salary links, result URL. Filter bar exposes: date posted, remote,
  company sector, job type, experience level, pay, education, developer skill,
  clearance type.
- Not accessible: full description/salary amount on the card itself (linked
  salary search instead); auth-gated employer resume features.
- Fields/filters: title, company, location, salary (linked), the full filter
  taxonomy (remote / job type / experience / pay / education / skills).

### 5. Glassdoor (glassdoor.com)

- Reachability: PARTIAL / INTERMITTENT on Firecrawl — same real search URL
  returned 403 four of five runs and 200 (62K chars) once; the one 200 was
  never confirmed to hold job cards, so treat Firecrawl as unreliable here.
  REACHABLE via CamoFox — real job cards rendered (verified).
- Accessible (via CamoFox tree): title, company, location, salary estimate
  ($XK–$YK Glassdoor est.), description, skills list, employer rating
  (e.g. 3.8), jobListingId, apply URL (jl=<id>). 30 jobListingIds / 60 apply
  URLs in one snapshot.
- Not accessible: full posting body without interaction (results sit lower in
  the page; need scroll/region-targeted read). Sign-in wall for company
  reviews/salary detail.
- Fields/filters: title, company, location, salary estimate, skills, rating,
  job id, apply URL, posting age.

### 6. Lever (jobs.lever.co)

- Reachability: UNVERIFIED. Initial test URL was wrong (jobs.lever.co/notion 404
  = notion is not a Lever customer). Not confirmed blocked or open. Needs a
  real board URL.
- Accessible: unknown pending valid test.
- Fields/filters: unknown pending valid test.

---

## Bottom line for job-hell app

You can pull a filterable listing feed from Firecrawl for Wellfound, LinkedIn,
and Greenhouse (one fast call each). Indeed and Glassdoor need CamoFox. Lever
is still unverified. Data quality varies:

- Best structured / least effort: Greenhouse, then Wellfound (salary + remote
  + location), then LinkedIn (but stale + no salary).
- Filter-first job pre-screen works best from Wellfound + Greenhouse +
  Glassdoor (salary + location + remote). LinkedIn is weak for pay filtering.
- Every site needs its own extractor; no single generic regex parses all of
  them (measured).

---

## Deep-research corrections (from per-site extractor research, 2026-09-04)

Each site was deep-researched by Devin ACP (primary pass) + an adversarial
antagonize pass. All per-site research lives in docs/<site>.md. Corrections to
the consensus above:

- **Glassdoor — Firecrawl is RELIABLE on the search feed, not intermittent.**
  Repeated scrapes returned statusCode 200 with real job cards (counts
  4,441–4,448 = live index churn). The earlier "~1/5 got 200" came from a
  different URL shape. The per-job detail page (`/job-listing/...?jl=`) is
  403/Cloudflare-blocked on BOTH cells. `?remoteWorkType=1`, `?fromAge=N`,
  `?easyApply=1`, `?minSalary=` all work as URL params. Pagination via
  `_IP<N>.htm`.
- **Lever — now VERIFIED via its public JSON API.**
  `api.lever.co/v0/postings/<slug>?mode=json` returns structured postings
  (title, location, workplaceType, date, description, applyUrl, hostedUrl,
  salary). No bot wall; Firecrawl reaches both the HTML board and the JSON API.
  Server-side filters: `department`, `location`, `commitment`, `team` — NOT
  `workplaceType` (client-side only).
- **Wellfound — best extraction is the embedded `__NEXT_DATA__` Apollo cache,**
  not markdown regex. Pagination is `?page=N` (server-honored). URL filters:
  role/location/remote/industry via path; salary/experience/job-type/recency
  are client-side only (`?job_type=` is ignored).
- **LinkedIn — no salary in feed; pagination + filters via the guest
  `jobs-guest` seeMore API.** Filters `f_TPR` (date), `f_WT` (remote),
  `f_AL`/`f_EA` (easy apply), `f_E` (experience). Feed is stale-heavy.
- **Greenhouse — legacy JSON API is DEAD.** Host migrated
  `boards.greenhouse.io → job-boards.greenhouse.io` (301). Data lives in the
  embedded `window.__remixContext` JSON blob (~33KB) in the embed HTML.
  No server-side filtering; pagination server-side only. `robots.txt` disallows
  `/embed/`.
- **Indeed — Firecrawl 403 stable; CamoFox required.** Extractor targets the
  rendered a11y tree; apply-redirect endpoints `/rc/clk?jk=` (organic) and
  `/pagead/clk` (sponsored). Robots denies `/` to most AI crawlers (ClaudeBot,
  GPTBot, DeepSeekBot, etc.) — scrape against ToS/compliance posture.

Recurring lesson for the app: every site's real data surface is either an
embedded JSON blob (`__NEXT_DATA__`, `__remixContext`) or the rendered
markdown/a11y-tree — there is no unified public API except Lever. So job-hell
needs a per-site extractor that greps the embedded JSON where present and falls
back to card parsing, with filters applied at URL time where the site honors
them (Glassdoor, LinkedIn, Lever, Wellfound page param) and client-side
otherwise.
