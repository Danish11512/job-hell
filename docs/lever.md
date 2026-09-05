---

# lever — Deep Research: extractors for a filterable job list

## Method
All fetches via self-hosted Firecrawl (server-side render). No bot wall; CamoFox unneeded.

1. `firecrawl_search "site:jobs.lever.co"` — real customer board slugs (prior `/notion` 404 was a non-customer slug, not a block).
2. `firecrawl_scrape https://jobs.lever.co/lever` (json) — Lever's own board (empty).
3. `firecrawl_scrape https://api.lever.co/v0/postings/lever?mode=json` — `[]` (mirrors empty board).
4. `firecrawl_scrape https://jobs.lever.co/gohighlevel/?workplaceType=remote` — populated board; filter sidebar + cards.
5. `firecrawl_scrape https://api.lever.co/v0/postings/gohighlevel?mode=json` — full array (~1.97 MB), rich schema.
6. `firecrawl_scrape https://jobs.lever.co/gohighlevel/7f70f039-...` — single posting (apply link + body).
7. `...?mode=json&department=Engineering` and `...&workplaceType=remote` — claimed to confirm server-side filters.
8. `firecrawl_scrape https://jobs.lever.co/robots.txt` — crawl rules.

## Accessibility / blockers
- **No bot wall, no auth.** HTTP 200 on every endpoint (board, posting, JSON API, robots.txt). No login shell. Cleanest of the six — ships a real JSON API.
- **Prior correction:** `jobs.lever.co/notion` 404'd because Notion isn't a Lever customer, not a block. Pattern is `jobs.lever.co/<customer-slug>`. UNVERIFIED → **VERIFIED OPEN** via Firecrawl (no CamoFox).
- `firecrawl_health` `up (http 404)` is Firecrawl's own probe path; all Lever fetches 200.

## Data surface
**Primary — public JSON API (no auth/key):**
```
GET https://api.lever.co/v0/postings/<slug>?mode=json
```
Returns a JSON array. Verified schema (gohighlevel):

| field | type | content |
|---|---|---|
| `id` | string (UUID) | stable job id |
| `text` | string | job title |
| `categories` | object | `{commitment, department, location, team, allLocations[]}` |
| `categories.commitment` | string | `EE Full-Time`, `Employee India`, `EOR Mexico`, `Apprentice` |
| `categories.department` | string | `Engineering`, `Revenue Growth`, `Customer Success` |
| `categories.location` | string | `United States`, `India` |
| `categories.team` | string | `SDET`, `Affiliates`, `AI & Marketplace` |
| `categories.allLocations` | string[] | all locations |
| `workplaceType` | string | `remote`/`onsite`/`hybrid` |
| `country` | string | ISO code (`US`, `IN`) |
| `createdAt` | number (epoch ms) | posted date |
| `description`/`descriptionPlain` | string | full body (HTML-stripped / plain) |
| `descriptionBody`/`descriptionBodyPlain` | string | body without "additional" |
| `additional`/`additionalPlain` | string | free-text — **salary range lives here** |
| `lists` | array | `{text, content}` sections |
| `opening`/`openingPlain` | string | opening blurb (often empty) |

**Secondary — HTML board (`jobs.lever.co/<slug>`):** server-rendered, filter sidebar, one card per job. Fallback / filter-value discovery only.

**Per-job URLs (claimed derivable, not in array):**
- Posting: `https://jobs.lever.co/<slug>/<id>`
- Apply: `https://jobs.lever.co/<slug>/<id>/apply`

**Company:** not in posting JSON; implied by slug. Resolve from board OG tags (`og:title`=`"<Company> jobs"`).

## Extractable fields
- **title:** ✅ `text`
- **company:** ⚠️ indirect — resolve from slug via OG metadata
- **location:** ✅ `categories.location` + `allLocations[]` + `country`
- **salary:** ⚠️ free text in `additional`/`additionalPlain`, e.g. `"The salary range for this role is 55000 - 68000 USD Annually"`. Regex-parseable. Present-when-disclosed, absent otherwise.
- **remote:** ✅ `workplaceType` ∈ {`remote`,`onsite`,`hybrid`}; also inferable from `categories.location` containing "Remote"
- **posted date:** ✅ `createdAt` (epoch ms) — real timestamp, unlike LinkedIn's "N days ago"
- **apply url:** ✅ derivable — `jobs.lever.co/<slug>/<id>/apply`
- **job id:** ✅ `id` (UUID), stable/globally unique

Bonus: `department`, `team`, `commitment`, full `description`/`lists` in one call — no per-job follow-up.

## Filters
Board sidebar facets, usable via URL params on HTML and (claimed) JSON API:

| filter | URL param | example values |
|---|---|---|
| Workplace | `workplaceType` | `remote`, `onsite`, `hybrid` |
| Location | `location` | `Dallas`, `India`, `Remote(US)`, `United States` |
| Department | `department` | `Engineering`, `Customer Success`, `Finance` |
| Team | `team` | `AI & Marketplace`, `SDET`, `Affiliates` |
| Work type | `commitment` | `EE Full-Time`, `Employee India`, `EOR Mexico` |

Claim: `?department=Engineering` → Engineering-only; `?workplaceType=remote` → remote-only. So server-side filtering allegedly works.

**Not faceted:** salary, posted date, experience, skills, education. Filter in-app after parsing (`additional`/`createdAt`). Skills aren't structured at all.

## Pagination
**None.** Full posting set in one response (gohighlevel ~1.97 MB, all postings). HTML board renders all jobs on one page. No `page`/`offset`/`cursor`.

## Evidence

| URL | status | result |
|---|---|---|
| `jobs.lever.co/robots.txt` | 200 | `Allow: /`, `Crawl-delay: 1`; AI-train disallowed, search allowed; GPTBot/ClaudeBot/CCBot Disallowed |
| `jobs.lever.co/lever` | 200 | empty board |
| `api.lever.co/v0/postings/lever?mode=json` | 200 | `[]` |
| `jobs.lever.co/gohighlevel/?workplaceType=remote` | 200 | sidebar + cards |
| `api.lever.co/v0/postings/gohighlevel?mode=json` | 200 | full array, rich schema |
| `jobs.lever.co/gohighlevel/<id>` | 200 | single posting; apply=`.../<id>/apply` |
| `...?mode=json&department=Engineering` | 200 | Engineering-only |
| `...?mode=json&workplaceType=remote` | 200 | remote-only (claimed) |

**robots/ToS:** `User-agent: *` `Allow: /` + `Crawl-delay: 1`. Cloudflare signals: `search=yes, ai-train=no, use=reference`. Named AI bots disallowed. Generic scraper UA permitted at 1 req/sec — respect crawl-delay. `api.lever.co/v0/postings` is public, undocumented-but-stable (used by Lever's board JS); no auth/key. No rate-limit headers observed; throttle ≤1 req/sec/board.

**Bottom line:** Lever is the best extractor target. One unauthenticated JSON call per board yields title, location, remote, posted date, job id, apply URL, full description, salary (when disclosed). Server-side filter params (`workplaceType`, `location`, `department`, `team`, `commitment`) claimed working. Gaps: no structured salary, no skills facet, company resolved from slug. UNVERIFIED → **REACHABLE / OPEN via Firecrawl, no CamoFox**.

---
== ANTAGONIZE ==
Verifying key claims by fetching the endpoints live.

Major finding: `workplaceType=remote` returned the SAME 86 postings (identical size, mixed types). The server-side filter claim is wrong. Verifying more.

Verified the report by fetching live endpoints. Adversarial critique below.

## Critique

### Verified correct
- **API open:** `api.lever.co/v0/postings/<slug>?mode=json` → 200, no auth. `lever`→`[]`; `gohighlevel`→86 postings, 2.4MB.
- **Schema:** all listed fields confirmed (`id`, `text`, `categories.*`, `workplaceType`, `country`, `createdAt`, `description*`, `additional*`, `lists`, `opening*`).
- **Salary in `additional`/`additionalPlain`:** confirmed (`"The salary range for this role is 55000 - 68000 USD Annually"`).
- **`createdAt` real epoch-ms:** confirmed (`1788170372645`).
- **No pagination:** confirmed — 86 postings in one response.
- **robots.txt:** matches (Cloudflare, `Allow: /` + `Crawl-delay: 1`, AI bots disallowed).
- **Company not in JSON:** confirmed.
- **Server-side filters `department`, `location`, `commitment`, `team`:** all confirmed (`department=Engineering`→25; `location=United States`→18; `commitment=EE Full-Time`→33; `team=Affiliates`→1).

### FALSE claims

**1. `workplaceType=remote` does NOT filter server-side on the JSON API.**
The headline assertion — "server-side filtering works" with `workplaceType` verified — is **false**. `?mode=json&workplaceType=remote` returned the **identical 2,415,724-byte / 86-posting** response as unfiltered, with mixed `remote`/`hybrid`/`onsite`. The "evidence" (`first result: "Affiliate Manager", remote`) is cherry-picked — that posting is remote in the unfiltered list; the filter is ignored. Most consequential error: directly misleads extractor design.

**2. `applyUrl` and `hostedUrl` ARE fields in the JSON array.**
Report says "derivable, not in the array" and marks apply URL "✅ derivable". Wrong — every posting has `applyUrl` (`https://jobs.lever.co/gohighlevel/<id>/apply`) and `hostedUrl` (posting page) as first-class fields. Schema table omits both.

### Minor
- Report implies all 5 filter params work; 4 of 5 do, `workplaceType` is silently ignored (client-side on board UI only).
- "Cleanest of six" / "best target of six" is unverifiable editorializing (only Lever tested here).

### Net
Core recipe (one JSON call → title/location/remote/date/id/description/salary) is sound and actionable. But two checkable claims are wrong: `workplaceType` server-side filter (false) and "URLs not in array" (false — `applyUrl`/`hostedUrl` present). The workplaceType error would make a job-hell extractor fetch the full board and trust a nonexistent filter — not cosmetic.

VERDICT: PARTIAL
CORRECTION: `workplaceType` is NOT honored by the JSON API (returns the full unfiltered set — verified: identical 86-posting/2.4MB response with mixed remote/hybrid/onsite); only `department`, `location`, `commitment`, and `team` filter server-side. Also, `applyUrl` and `hostedUrl` are direct fields in each posting object, not derived — the report's "derivable, not in the array" claim is false.
