# job-hell — Initial Research

Consensus of what's reachable, blocked, and filterable per job site. Live scrape experiment + per-site extractor deep research (2026-09-04), Firecrawl (linux-mint:3002) + CamoFox (remote).

GOLDEN RULE: Firecrawl HTTP 200 ≠ success (e.g. Glassdoor returned 200 with only a landing shell). Validate on real job fields (title/company/location/salary/apply URL), not status.

## Per-site

| Site | Tier | Accessible | Blocked | Filters |
|---|---|---|---|---|
| Wellfound | Firecrawl | full cards (title/company/loc/salary/remote/date) | none (listing level) | URL: role, location, remote, industry. Client-side: salary, exp, type, recency |
| LinkedIn | Firecrawl (guest seeMore) | cards (title/company/loc/age/apply url) | salary, full body, easy-apply (auth); detail ok | URL: date, remote, easy-apply, <10 applicants, experience. NO salary |
| Greenhouse | Firecrawl + JSON API | full in JSON API (title/loc/content/dept/date/timestamps) | salary, remote boolean | local-only (dept/loc/text/recency) — no server filter |
| Indeed | CamoFox (required) | cards (title/company/loc/salary-partial/type/benefits) | Firecrawl 403; full body | URL: kw, loc, fromage, remote, type, explvl, pay, sort |
| Glassdoor | Firecrawl (feed) + CamoFox | feed cards (title/company/loc/salary/skills/rating) | per-job detail (403/Cloudflare both tiers) | URL: remote, date, easy-apply, salary, kw/loc in path |
| Lever | Firecrawl + JSON API | full in JSON API (title/loc/remote/date/id/apply/salary-in-additional) | salary not structured; skills | JSON API: dept, location, commitment, team. NOT workplaceType |

## Best data surfaces (for job-hell)
- **Greenhouse** — `boards-api.greenhouse.io/v1/boards/<org>/jobs?content=true` (200, valid JSON, 171 jobs/sample). ALIVE (an earlier note said dead — wrong, malformed URL).
- **Lever** — `api.lever.co/v0/postings/<slug>?mode=json` (one call = full board, rich fields + real timestamp).
- **Wellfound** — `<script id="__NEXT_DATA__">` Apollo cache (structured), not markdown regex.
- **LinkedIn** — guest seeMore endpoint (paginates) + `f_TPR`/`f_WT` filters.
- **Indeed** — CamoFox a11y tree; `jk` job keys; `start` pagination (cap 90 per robots).
- **Glassdoor** — card markdown; `_IP<N>.htm` pagination; URL-param filters. Detail blocked.

## Bottom line
Reachable + filterable feeds are achievable for all six. Best structured / least effort: Greenhouse JSON API, Lever JSON API, Wellfound `__NEXT_DATA__`. LinkedIn weak on salary. Indeed needs CamoFox. Glassdoor detail body unreachable (clean-IP browser required). ToS/robots risk: Indeed (AI-crawler deny `/`), LinkedIn (scraping prohibited), Greenhouse/Lever robots flags. Needs one extractor per site — no unified API except Lever.