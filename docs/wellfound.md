# wellfound — Deep Research (verified)

## Method
Fetched live via self-hosted Firecrawl (server-side render). No bot wall; CamoFox unneeded. All URLs returned 200 `text/html`.

1. `/jobs` — trending feed
2. `/robots.txt`
3. `/role/l/software-engineer/united-states` — role+location list
4. `…?page=2` — pagination
5. `…?job_type=internship` — query-param filter probe
6. `/remote`
7. `/jobs/4670578-software-engineer` — job detail

## Accessibility
- No bot wall, no auth shell, no 403/Cloudflare. Cards guest-readable.
- Auth only for "Apply Now" submission and disallowed paths (`/jobs/applications`, `/profile/*`, `/u/`).
- No 429 observed; unverified at scale.

## Data surface
- **No public REST/GraphQL endpoint**, but raw HTML embeds `<script id="__NEXT_DATA__">` (~256KB) with an **Apollo GraphQL cache** (`pageProps.apolloState.data`): 141 entities, typed `JobListingSearchResult` objects with `title, compensation, jobType, remote, remoteConfig, yearsExperienceMin/Max, locationNames, liveStartAt, id, slug, description`. Firecrawl strips `<script>` in markdown, so this is invisible to markdown-only inspection.
- **URL contract (path-based, server-honored):**
  - `/jobs/<id>-<slug>` → job detail (numeric id is the stable key)
  - `/role/l/<role>/<location>`, `/role/r/<role>` (remote), `/role/<role>`
  - `/location/<location>`
  - `/remote`
  - `/startups/industry/<industry>`
  - `/company/<slug>` (+ `/funding`, `/culture_and_benefits`)
- **robots.txt** (`User-agent: *`): disallows `/_jobs/`, `/*?role=*`, `/*?jobId=*`, `/*?jobSlug=*`, `/*?preview=*`, `/*?inFrame=*`, `/*?after_sign_in=*`, `/auth/`, `/cdn-cgi/`, `/search`, `/jobs/applications`, `/jobs/signup`, `/profile/edit`, `/profile/notifications`, `/profile/review`, `/profile/resume`, `/u/`, `/re/`, `/recruit/dashboard`, `/onboarding`, `/projects/`, `/embed/`, `/job_listings/report_company`, `/job_profiles/embed`, `/social/share_modal`, `/documents/`. Sitemaps: `/sitemap.xml.gz`, `/blog-index.xml.gz`. Path-form `/role/...` and `/jobs/<id>` allowed; `?role=` query form disallowed.

## Extractable fields
Prefer the `__NEXT_DATA__` Apollo cache (structured). Card-text fields below are the rendered fallback.

**Rich card (`/role/l/...`):** company block (logo, name, "Actively Hiring", description, headcount, tags) then per-job: title link, job type, salary range, remote flag • location `[+N]`, years exp, relative posted age, Save/Apply.

**Compact card (`/jobs`):** `title • company • remote • location • salary • [+ equity] • posted age`.

- **title:** link text of `[<title>](/jobs/<id>-<slug>)`.
- **company:** rich-card link text or first `•` token; slug in URL.
- **location:** text after remote flag; multi-location shows `+N`.
- **salary:** `$low k–$high k` (also €/£); absent on some cards. JSON has structured `compensation`.
- **remote:** `Remote only` / `Onsite or remote` / `In office` / `Remote` / omitted. JSON has `remote` + `remoteConfig`.
- **posted date:** card shows relative age only; **JSON `liveStartAt` is absolute**.
- **apply url:** the `/jobs/<id>-<slug>` link.
- **job id:** numeric prefix of `/jobs/<id>-<slug>` — primary key.
- **Extras:** job type, equity, years exp, "Actively Hiring" badge, company size/stage/industries/funding (detail page).

## Filters
**URL-addressable (path, server-honored):**
- role — `/role/l/<role>/<location>`, `/role/r/<role>`, `/role/<role>`
- location — path segment (`united-states`, `san-francisco-bay-area`, …)
- remote — `/remote` (11,755 results) or `/role/r/<role>`
- industry — `/startups/industry/<industry>`

**NOT URL-addressable (verified):** `?job_type=internship` returned identical `2978 results` and identical first cards — ignored/stripped. Salary/experience/job-type/recency are client-side JS filters, not query params. robots also disallows `?role=`, `?jobId=`, `?jobSlug=`, `?preview=`.

**For job-hell:** use path filters at fetch time; apply salary/experience/job-type/recency client-side — either on extracted card text or, preferably, directly on the `__NEXT_DATA__` structured fields. One Firecrawl call per (role, location) tuple gives a fully filterable pre-screen list.

## Pagination
- `?page=N` honored server-side. Verified: `?page=2` → `Page 2 of 54`, distinct jobs (Gray Swan AI, Kodiak, Virta Health, Astranis).
- Totals printed in feed: `#### 2978 results total` / `#### Page 1 of 54` (software-engineer/US); `#### 11755 results total` / `#### Page 1 of 206` (`/remote`). Live totals fluctuate.
- ~20–25 company blocks / ~30–40 job rows per page.
- No "Next" link in markdown (JS button); just increment `?page=N`. Not in robots disallow.

## Evidence
| URL | status | result |
|---|---|---|
| `/jobs` | 200 | trending feed, compact cards (DoseSpot, ZioSec, Tamarack…) |
| `/robots.txt` | 200 `text/plain` | disallows listed above; allows `/role/`, `/jobs/<id>`, `/remote`, `/location/` |
| `/role/l/software-engineer/united-states` | 200 | `2978 results`, `Page 1 of 54`, rich cards (Ethos $96k–$169k, Novig $200k–$260k, Agave $130k–$210k/1yr) |
| `…?page=2` | 200 | `Page 2 of 54`, different jobs → pagination confirmed |
| `…?job_type=internship` | 200 | identical to no-param → query filter IGNORED |
| `/remote` | 200 | `11755 results`, `Page 1 of 206` |
| `/jobs/4670578-software-engineer` | 200 | `$96k–$169k`, `Onsite or remote`, `Hires remotely in Everywhere`, `Visa Sponsorship Not Available`, `Posted: 1 day ago`, funding $406.5M |

## Corrections to `docs/initial-research.md`
- "Pagination page-2 unverified" → page 2 reachable via `?page=N`; 54–206 pages depending on filter.
- Filters listed as "available in data" without URL/client distinction → only role/location/remote/industry are URL-addressable; salary/experience/job-type/date are client-side (`?job_type=` ignored).
- "33 unique cards on homepage" → homepage is the trending feed (compact cards); the filterable feed is `/role/l/...` with richer grouped cards — target that.

VERDICT: PARTIAL
CORRECTION: The raw HTML contains a 256KB `<script id="__NEXT_DATA__">` blob holding an Apollo GraphQL cache (`pageProps.apolloState.data`) with structured `JobListingSearchResult` entities (title, compensation, jobType, remote, remoteConfig, yearsExperienceMin/Max, locationNames, liveStartAt, id, slug, description). The report's claim of "no __NEXT_DATA__ blob / no embedded JSON / extraction must work from markdown" is false — it resulted from Firecrawl stripping script tags. `liveStartAt` is an absolute posted timestamp, contradicting "no absolute ISO date available." The correct primary extraction strategy is parsing this JSON, not regex over markdown card text. (Minor: robots.txt disallows specific `/profile/{edit,notifications,review,resume}` paths, not `/profile/*` as reported.)
