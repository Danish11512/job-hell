# Glassdoor — extractors

STATUS: PARTIAL (live 2026-09-05; Firecrawl + CamoFox). Feed reachable; detail BOTH tiers blocked.

## Fetch — flaky, needs retry + option
- FireCrawl on search feed `/Job/...SRCH...htm?jl=` → **flaky**: plain scrape hits `document_antibot` 500 most tries. Adding `waitFor: 8000ms` + retry got through → **62KB real job cards**. Same config sometimes still 500 — retries mandatory.
- CamoFox (any backend) also reaches the feed → 57KB a11y tree, real cards.
- Per-job detail `/job-listing/<slug>?jl=<id>` → BLOCKED on BOTH tiers (Firecrawl 403; CamoFox Cloudflare "Humans only"). No full body without clean-IP/residential browser.

## Data surface
Cards server-rendered into markdown / a11y tree. Card schema:
```
company + rating
[<Title>](/job-listing/<slug>-JV_...?jl=<jobListingId>)
<Location>   # "Dallas, TX" | "Remote"
<Salary>     # "$65K - $101K (Glassdoor est.)" | "$18.50/hr (Employer provided)"
Easy Apply [badge]
<snippet>…&hellip;   **Skills:** <csv>
/<partner/jobListing.htm?...&jobListingId=   # apply
<postedAge>   # 24h|4d|30d+
```
Job id = `jl`/`jobListingId` (13-digit).

## Extractable fields
title, company (e.g. CSI Companies), location, salary (Glassdoor est. or Employer provided), skills, easy-apply badge, apply URL, rating, posted age. Relative dates only.

## Filters (URL params, server-side — verified)
`remoteWorkType=1` (2,180 jobs), `fromAge=N` (=7 → 438 + "Last week"), `easyApply=1`, `minSalary=`. Keyword/location in SRCH path. One GET = pre-filtered feed.

## Pagination
`_IP<N>.htm` suffix (page 2 = `..._KO14,26_IP2.htm`), ~30 cards/page.

## ToS
robots disallows `/ajax/`, `/jobview/`, `/partner/`, `/profile/`; `/Job/` allowed.

## Verdict
PARTIAL. Feed + filters + pagination work via Firecrawl (waitFor+retry) or CamoFox. Detail body unreachable both tiers. Never trust a bare Firecrawl 200 from Glassdoor — verify job cards present.