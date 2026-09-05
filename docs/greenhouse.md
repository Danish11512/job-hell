Firecrawl scraped the embed board (200, markdown). Probed curl, robots.txt, per-job embed, pagination, filter params, and the legacy JSON API.

---

# greenhouse - Deep Research: extractors for a filterable job list

## Method
1. **Firecrawl scrape** of embed board URL → HTTP 200, ~30K markdown, one-row-per-job tables.
2. **curl -L** of embed HTML → Remix SPA embedding `window.__remixContext` (~33KB JSON blob).
3. **curl -L** of legacy `boards-api.greenhouse.io` (`/departments`, `/jobs`, `/jobs/<id>`) → all dead.
4. **curl** of `?page=2/4/5` and filter variants (`department_id`, `office_id`, `location`, `query`, `sort`).
5. **curl** of `/embed/job_app?gh_jid=` and canonical job detail route.
6. **curl** of `robots.txt` on both hosts.

CamoFox unnecessary — no 403, no auth shell.

## Accessibility / blockers
- **No bot wall, no auth, no 403.** Firecrawl + plain curl both 200.
- **Host migration:** `boards.greenhouse.io/embed/job_board?for=airbnb` 301→ `job-boards.greenhouse.io/...`. New canonical host.
- **Legacy JSON API DEAD.** `boards-api.greenhouse.io/departments?token=airbnb` and `/jobs?...` 301→404. Per-job `/jobs/<id>?token=` 404 directly. Don't rely on it.
- **robots.txt caveat:** both hosts `Disallow: /embed/`. No technical enforcement, but a ToS flag. Page also emits `<meta name="robots" content="noindex">`.
- **No rate-limit headers observed**; not stress-tested.

## Data surface
Not a REST API — a **Remix SSR page** embedding the loader payload inline:

```
window.__remixContext = { ... };
```

Path:
```
state.loaderData["routes/embed.job_board"]
  ├── jobPosts: { count, page, total, total_pages, data:[ ...50... ] }
  ├── featuredPosts:[]
  ├── board: { name, public_url, content, redirect_to }
  ├── departments:[ {id,value,name,label} ...27 ]   // filter taxonomy
  ├── offices:[ {id,value,name,label,children:[...]} ...4 ] // region→country→city
  ├── customFields:[]      // empty for Airbnb
  ├── customFieldFilters:{}// empty for Airbnb
  ├── departmentIds:[] officeIds:[]   // active filter state (always [])
  └── urlToken:"airbnb"
```

Each `jobPosts.data` entry:
```json
{
  "id": 7732569, "title": "(Contract) Senior Data Scientist, ...",
  "internal_job_id": 3393194, "updated_at": "2026-09-04T20:19:40-04:00",
  "published_at": "2026-03-18T13:37:03-04:00", "requisition_id": "CW",
  "location": "United States",
  "absolute_url": "https://careers.airbnb.com/positions/7732569?gh_jid=7732569",
  "department": { "name": "Data Science", "id": 85549, "path": ["1. Technical"] },
  "is_featured": false
}
```

No `next-data`, no GraphQL, no XHR. Full page-1 payload ships in HTML. No per-job JSON endpoint remains.

**Extractor recipe:** curl embed HTML → regex `window\.__remixContext\s*=\s*(\{.*?\});` → `json.loads` → walk to `state.loaderData["routes/embed.job_board"].jobPosts.data`. Cleaner than Firecrawl markdown; yields `published_at`/`updated_at`/department path the markdown omits.

## Extractable fields
- **title:** ✅ `jobPosts.data[].title`
- **company:** ✅ from `board.name` / `urlToken` (not per-row)
- **location:** ✅ `jobPosts.data[].location` (free-text; e.g. `"Remote - USA"`, `"San Francisco, CA"`, `"Bangalore, India"`). Structured geo lives in `offices` tree but jobs carry no `office_id` — only text.
- **salary:** ❌ absent from feed. Only on employer's custom detail page (Airbnb: `careers.airbnb.com/positions/<id>` has `<div class="pay-range">$140—$150 USD</div>`). Per-employer HTML, no generic Greenhouse extractor.
- **remote flag:** ❌ no boolean. Inferable via `location` substring (`"Remote"`). Decent for Airbnb, not normalized across employers.
- **posted date:** ✅ `published_at` + `updated_at` (ISO 8601). Markdown omits these; JSON blob has them.
- **apply URL:** ✅ `absolute_url` (employer custom domain, else `job-boards.greenhouse.io/<token>/jobs/<id>`).
- **job id:** ✅ `id` (= `gh_jid`); also `internal_job_id`, `requisition_id`.

## Filters available
- **Department** — `departments[]` (27 for Airbnb), grouped by `department.path`.
- **Office/Location** — `offices[]` nested tree (AMER→US→SF; APAC→India→Bangalore; EMEA→UK→London; LATAM→Brazil→São Paulo).
- **Free-text search** — client-side.
- **Custom fields** — `customFields[]`/`customFieldFilters{}`; employer-configurable, empty for Airbnb.

**Critical:** URL params do NOT drive server-side filtering:

| URL param | result |
|---|---|
| `?department_id=247` | total 171, `departmentIds=[]`, first row unchanged |
| `?office_id=55` | total 171, `officeIds=[]` |
| `?location=Remote` | total 171 |
| `?query=Engineer` | total 171 |
| `?sort=desc` | total 171 |

SSR returns full unfiltered page-1; filtering is client-side post-hydration, only across the loaded 50. Server honors only `?page=N` and `?for=<token>`.

**Strategy:** fetch all 4 pages (171), merge `jobPosts.data`, filter locally in Python by `department.id`, `location` substring, `title` keyword, `published_at` recency.

## Pagination
- Server-side `?page=N`:
  - page=1 → 50, `total=171`, `total_pages=4`
  - page=2 → 50 (first: "Tech Lead Manager, Oracle ERP", id 8102684)
  - page=4 → 21 (first: "Senior Market Manager, Hotels", id 7587869)
  - page=5 → 0 (out of range, empty `data`, no error)
- 50/page, 4 pages, 171 total. `total_pages` authoritative. No cursor/`Link`. Trivial.

## Verified against
| URL | result |
|---|---|
| `boards.greenhouse.io/embed/job_board?for=airbnb` (Firecrawl) | 200, ~30K markdown, 33 cards in sample; redirects to `job-boards.` |
| `job-boards.greenhouse.io/embed/job_board?for=airbnb` (curl -L) | 200, 58962 bytes, `__remixContext` 33454 chars, `total=171`, `total_pages=4`, 50 jobs |
| `&page=2` | 200, 62842 bytes, page=2, 50 jobs, first id=8102684 |
| `&page=4` | 200, 38379 bytes, 21 jobs, first id=7587869 |
| `&page=5` | 200, 21411 bytes, 0 jobs |
| `&department_id=247`/`&office_id=55`/`&location=Remote`/`&query=Engineer`/`&sort=desc` | all 200, ~59KB, `total=171`, `departmentIds=[]`/`officeIds=[]` → **no server-side filtering** |
| `boards-api.greenhouse.io/departments?token=airbnb` (curl -L) | 301→404 — legacy API removed |
| `boards-api.greenhouse.io/jobs?token=airbnb&content=true` (curl -L) | 301→404 |
| `boards-api.greenhouse.io/jobs/8154749?token=airbnb` | 404 |
| `job-boards.greenhouse.io/embed/job_app?for=airbnb&gh_jid=7732569` (and 8031907, 8130355) | 302→`...&error=true` → **job_app embed broken** |
| `job-boards.greenhouse.io/airbnb/jobs/7732569` (curl -L) | 302→`careers.airbnb.com/positions/7732569/?gh_jid=7732569` → 200, 47308 bytes (Airbnb custom WordPress page); has `Pay Range: $140—$150 USD` |
| `boards.greenhouse.io/robots.txt` | 200, `Disallow: /embed/` |
| `boards-api.greenhouse.io/robots.txt` | 200, `Disallow: /embed/` |

**Corrections to `docs/initial-research.md`:**
- Initial: "no salary in board feed" — confirmed; extended: salary only on employer's custom detail page (no generic extractor).
- Initial listed title/location/job-board URL/department — extended with `published_at`, `updated_at`, `requisition_id`, `internal_job_id`, `is_featured`, `absolute_url` (via `__remixContext`, not markdown).
- Initial didn't document the data surface — added: Remix SSR + `window.__remixContext` is the real target.
- Initial didn't note host migration (`boards.`→`job-boards.`) or that legacy `boards-api.greenhouse.io` JSON API is dead.
- Initial didn't note `robots.txt` `Disallow: /embed/`.

---
== ANTAGONIZE ==
Verified by probing live endpoints:

| Claim | Verification |
|---|---|
| `boards.greenhouse.io/embed/...` 301→`job-boards.greenhouse.io` | ✅ Confirmed 301 |
| Legacy `boards-api.greenhouse.io/departments?token=` 301→404 | ✅ Confirmed 301 then 404 |
| `window.__remixContext` JSON blob, `total=171` | ✅ Confirmed |
| `robots.txt` `Disallow: /embed/` on both hosts | ✅ Confirmed verbatim |
| `?page=N` pagination, `total_pages=4`, page 5 empty `data:[]` | ✅ Confirmed |
| Filter params (`department_id=247`) not honored (total 171, `departmentIds=[]`) | ✅ Confirmed |
| `job_app` embed broken → `error=true` | ✅ Confirmed (302, answer said 301 — minor) |
| Job detail → `careers.airbnb.com/positions/7732569` | ✅ Confirmed (302, answer said 301 — minor) |
| Airbnb detail has "Pay Range" `$140—$150 USD` | ✅ Confirmed |

All substantive claims hold: host migration, dead legacy API, Remix `__remixContext` surface, server-side pagination only, no server-side filtering, broken `job_app` embed, salary only on employer detail, robots.txt caveat.

Only inaccuracies: two redirects labeled `301` are actually `302` (`job_app` and job-detail route). Doesn't affect any conclusion — targets and behavior exactly as described.

VERDICT: VERIFIED
