# LinkedIn — extractors

STATUS: VERIFIED (live 2026-09-04; Firecrawl + curl)

## Fetch
Guest search via Firecrawl, no bot wall, no auth. Feed ~25 cards/page, ~30K chars.

## Best data surface
Guest "seeMore" card endpoint (cleaner than full page, paginates):
`linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search?keywords=<kw>&<filters>&start=<N>`
`start=0,25,50...` paginates (verified). Full page's `?start=` does NOT paginate (ignored).

## Extractable fields (card)
title (`###`), company (`####`), location, posted-age (relative only, no absolute ISO), apply URL (`/jobs/view/<slug>-<jobId>`), job id (numeric suffix). Detail page (`/jobs/view/...`) adds seniority, employment type, function, industries, applicant count.
- salary: ABSENT from feed (no structured field) — weak for pay filtering. Only turns up inside titles.
- remote: not on card; infer via `f_WT` filter.

## Filters (URL params, server-side — verified)
keywords, `f_TPR` (date: r86400=24h / r604800=wk / r2592000=mo), `f_WT` (1 onsite/2 remote/3 hybrid), `f_AL` (easy apply), `f_EA` (<10 applicants), `f_E` (1-6 experience). `f_JT`/`f_SB2` (job type/salary) unconfirmed. Compose with seeMore + paginate.

## Blocks / ToS
robots: `/jobs-guest/`, `/api/jobPostings/jobs*`, `/jsearch*`, `/voyager/api` disallowed for crawlers. ToS prohibits unauthorized scraping — legal risk.

## Verdict
PARTIAL (seeMore pagination validated; `f_E` evidence confounded, filter effect not isolated). Strategy: seeMore + `f_TPR`/`f_WT` + parse cards; no salary.