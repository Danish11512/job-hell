# job-hell — Initial Research

Consensus of what's reachable, blocked, and filterable per job site. Live scrape experiment (2026-09-04/05), Firecrawl (linux-mint:3002) + CamoFox (remote + local). Every claim below verified by real execution.

GOLDEN RULES:
- Firecrawl HTTP 200 ≠ success (Glassdoor returned 200 with only a landing shell). Validate on real job fields, not status.
- Firecrawl `document_antibot` 500 / thin 200 = bot wall → escalate.
- CamoFox backend choice matters: **remote** (linux-mint exit IP) clears sites the **local** IP gets Cloudflare-blocked on (Indeed).

## Escalation ladder (per site)
1. FireCrawl `scrape` (fast).
2. FireCrawl + `waitFor: 8s` + retry (kills flaky walls, e.g. Glassdoor).
3. CamoFox **remote** backend (hard walls): Indeed, ZipRecruiter.

## Per-site

| Site | Works via | Accessible | Blocked |
|---|---|---|---|
| Wellfound | FireCrawl | full cards + salary + remote + date | none |
| LinkedIn | FireCrawl (guest seeMore) | cards; url: date/remote/easy-apply/exp | salary, full body |
| Dice | FireCrawl | cards + salary + employment type | none |
| Greenhouse | FireCrawl + JSON API | full in JSON API (title/loc/content/dept/date) | salary, remote bool |
| Lever | FireCrawl + JSON API | full JSON (title/loc/remote/date/id/apply) | salary not structured |
| Glassdoor | FireCrawl (waitFor+retry) / CamoFox | feed cards + salary + skills + filters | detail body (both tiers) |
| Indeed | CamoFox remote | cards + salary + filters | FireCrawl + local IP |
| ZipRecruiter | CamoFox | cards + salary + quick apply | FireCrawl |
| Monster | NOT retried | — | — |

## Best data surfaces (for job-hell)
- **Greenhouse** — `boards-api.greenhouse.io/v1/boards/<org>/jobs?content=true` (200, valid JSON, 171 jobs). 
- **Lever** — `api.lever.co/v0/postings/<slug>?mode=json` (one call = full board, real timestamp).
- **Wellfound** — `<script id="__NEXT_DATA__">` Apollo cache (structured).
- **LinkedIn** — guest seeMore endpoint (paginates) + `f_TPR`/`f_WT`.
- **Indeed** — CamoFox remote a11y tree; `jk` keys; `start` pagination (cap 90).
- **ZipRecruiter** — CamoFox a11y tree; `/jobs-search?search=<kw>`.
- **Dice / Glassdoor** — FireCrawl markdown (Dice clean; Glassdoor waitFor+retry).

## Bottom line
7 of 8 tested boards are scrapeable. Best / least effort: Greenhouse + Lever JSON APIs, Wellfound `__NEXT_DATA__`, Dice markdown — no anti-bot. Needs CamoFox: Indeed (remote backend), ZipRecruiter. Glassdoor feed reachable but detail body unreachable (clean-IP browser required). ToS risk: Indeed + LinkedIn restrict automated scraping. One extractor per site — no unified API except Lever.