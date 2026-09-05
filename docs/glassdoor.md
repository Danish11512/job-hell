# Glassdoor — extractors

STATUS: PARTIAL (live 2026-09-04; Firecrawl + CamoFox). Note: one earlier draft fabricated a rawHtml fetch — that data-surface section is unverified.

## Fetch
Search feed `/Job/...SRCH_IL.0,13_IN1_KO14,26.htm` = OPEN on Firecrawl (statusCode 200, real cards, 4,441–4,448 stable = index churn). CamoFox also reaches it.
Per-job detail `/job-listing/<slug>?jl=<id>` = BLOCKED on both tiers (Firecrawl 403; CamoFox = Cloudflare "Humans only"). No full posting body without a clean-IP/residential browser.

## Best data surface
Cards are server-rendered into the markdown/a11y tree — card markup IS the data. No public JSON API confirmed. Stable per-job id = `jl`/`jobListingId` (13-digit, e.g. 1010202371231).

## Extractable fields (card schema)
company + rating, title, location ("Dallas, TX"/"Remote"), salary (`$65K - $101K (Glassdoor est.)` / `(Employer provided)` / `$65.00-$70.00 Per Hour`), Easy Apply badge, snippet, `**Skills:**` (5/card), apply URL (`/partner/jobListing.htm?...&jobListingId=`), posted age (relative `24h`..`30d+`, no absolute).

## Filters (URL params, server-side — verified)
`remoteWorkType=1` (remote → 2,180 jobs), `fromAge=N` (=7 → 438 jobs + "Last week"), `easyApply=1`, `minSalary=<cents?>` (=100000 → "$100K - $3M"). Keyword/location in SRCH path. One GET = pre-filtered feed.

## Pagination
`_IP<N>.htm` suffix. Page 2 = `..._KO14,26_IP2.htm` (distinct results, `pos=201+` vs page-1 `pos=101+`), ~30 cards/page. Total in H1 → page count.

## ToS
robots disallows `/ajax/`, `/jobview/`, `/partner/`, `/profile/`; `/Job/` allowed.

## Verdict
PARTIAL. Feed + filters + pagination = solid on Firecrawl. Detail body = blocked both tiers. Data-surface/raw-HTML section needs re-verification (don't trust the fabricated fetch).