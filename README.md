# job-hell

Job listing extractor research for a job pre-screen app — pull listings from bot-protected job sites, filter into a list before applying.

## docs/
- `initial-research.md` — consensus: what's reachable/blocked/filterable per site + best data surface.
- `wellfound.md` `linkedin.md` `greenhouse.md` `indeed.md` `glassdoor.md` `lever.md` — per-site extractor deep research (fetch path, fields, filters, blocks, ToS). Each produced by Devin ACP primary + antagonize pass; ends with VERDICT (+ CORRECTION where the critique found an error).

## Stack
- Firecrawl (self-hosted v2.11.162) — fast tier, no bot wall.
- CamoFox (anti-detection browser) — escalation for hard walls.
- Devin ACP (glm-5-2) — deep-research passes (primary + adversarial).

## Key extractor facts
- Best structured: **Greenhouse** legacy JSON API (`boards-api.greenhouse.io/v1/boards/<org>/jobs`), **Lever** JSON API (`api.lever.co/v0/postings/<slug>?mode=json`), **Wellfound** `__NEXT_DATA__` Apollo cache.
- Hardest: **Indeed** (Firecrawl 403 → CamoFox), **Glassdoor** detail page (blocked both tiers).
- Recurring pitfall: per-site data surface differs (JSON blob vs card pattern) — one extractor per site, no single endpoint.