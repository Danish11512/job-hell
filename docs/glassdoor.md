# glassdoor — Deep Research: extractors for a filterable job list

## Method (what I actually fetched)

Live fetches 2026-09-04 via the hermes toolchain (self-hosted Firecrawl v2 on
100.121.96.42:3002 + CamoFox remote on 100.121.96.42:9377). Target:
`https://www.glassdoor.com/Job/united-states-react-native-jobs-SRCH_IL.0,13_IN1_KO14,26.htm`

Fetched, in order:
1. Firecrawl scrape (markdown) of base SRCH URL — real job cards.
2. Firecrawl scrape (`--json`) — statusCode 200, title "4,437 react native
   Jobs in United States".
3. CamoFox open + snapshot — full a11y tree, same cards (4,447 count).
4. Firecrawl scrape of `_IP2.htm` (page 2) — different results, `pos=201+`.
5. Firecrawl scrape of `?remoteWorkType=1&fromAge=7` — 60 jobs, "Last week".
6. Firecrawl scrape of `?easyApply=1&minSalary=100000` — 4,051 jobs.
7. Firecrawl scrape of base again — 4,442 jobs (index churn, not instability).
8. (Flagged by critique — see integrity note below.)
9. Firecrawl scrape of a per-job `/job-listing/...?jl=...` detail — 403.
10. CamoFox navigate+snapshot of that detail — Cloudflare "Humans only".
11. `curl robots.txt` — 200, full rules.

## Integrity note (from the antagonize pass — broadcast loudly)

The original primary report claimed a raw-HTML fetch (fetch #8, "950,927
chars") used to inspect embedded JSON. That fetch is FABRICATED: the
`firecrawl_scrape` MCP schema accepts only `url` + `json` — there is no
`formats` / `rawHtml` parameter. Everything derived from it (the "24
`window.GD_*` matches", "no `__NEXT_DATA__`", "no `application/ld+json`") is
UNVERIFIED and likely wrong — every scraped page contains a `#__next` skip-link
(Next.js root), so a `__NEXT_DATA__`/RSC blob almost certainly exists. Treat the
"Data surface" conclusions below as NOT established until confirmed by a method
that can retrieve raw HTML (e.g. CamoFox `navigate` + evaluating
`document.getElementById('__NEXT_DATA__')`, or the Firecrawl `crawl` rawHtml
path if supported by the deployment).

## Accessibility / blockers (verified)

- Search feed (`/Job/...SRCH...htm`): OPEN on Firecrawl. statusCode 200, real
  cards in markdown, stable across re-runs (counts 4,441–4,448 = live churn).
  **Corrects initial-research**: Firecrawl is reliable on the SRCH feed, not
  "intermittent 403." CamoFox also reaches it.
- Per-job detail page (`/job-listing/<slug>.htm?jl=<id>`): BLOCKED on both
  tiers. Firecrawl 403; CamoFox hits Cloudflare "Humans only" (remote browser's
  exit IP 108.6.134.152 is flagged). Full posting body unreachable without a
  residential/clean-IP browser profile.
- Apply/redirect (`/partner/jobListing.htm?...`): in card markup, but
  `robots.txt` disallows `/partner/`; apply-link only.
- No login wall on the search feed. Salary estimates + skills shown to
  anonymous users.

## Data surface (UNVERIFIED — see integrity note)

No public JSON API confirmed. The card markup itself carries the data. The only
confirmed per-job identifier is `jl`/`jobListingId` (13-digit, e.g.
`1010202371231`) on both the SEO URL and the partner apply URL. (`/ajax/` XHR
endpoints exist but are robots-disallowed and were NOT needed.)

## Extractable fields (verified card schema)

```
<Company> <rating>          # rating e.g. 3.3, ONLY if rated
[<Title>](/job-listing/<slug>-JV_...?jl=<jobListingId>)
<Location>                  # "Dallas, TX" | "Remote" | "United States"
<Salary>                    # "$65K - $101K (Glassdoor est.)"
                            #  | "$73K - $174K (Employer provided)"
                            #  | "$65.00 - $70.00 Per Hour (Employer provided)"
Easy Apply                  # OPTIONAL badge
<snippet>…&hellip;
**Skills:** <comma-separated>
[apply link](/partner/jobListing.htm?...&jobListingId=<id>...)
<postedAge>                 # "24h" | "4d" | "25d" | "30d+"
```

- title: PRESENT (link text). company: PRESENT. location: PRESENT.
- salary: PRESENT ((Glassdoor est.) or (Employer provided); absent on some
  cards, e.g. AuraOne).
- remote flag: DERIVED from location == "Remote", or `remoteWorkType=1`.
- posted date: PRESENT, relative only (`24h`..`30d+`); combine `fromAge=N`.
- apply URL: PRESENT (`/partner/jobListing.htm?...&jobListingId=`) — real
  apply endpoint. `/job-listing/...?jl=` = canonical permalink/id carrier.
- job id: PRESENT (`jl=` / `jobListingId=`).
- extras: company rating, skills (5/card), easy-apply badge, snippet.

## Filters available (all URL-addressable, verified)

| UI chip          | URL param                | Verified effect               |
|------------------|--------------------------|-------------------------------|
| Remote only      | `remoteWorkType=1`       | feed restricted to remote     |
| Date posted      | `fromAge=N`              | `=7` → "Last week", 60 jobs   |
| Easy Apply only  | `easyApply=1`            | chip "Easy Apply only"        |
| Salary range     | `minSalary=<cents?>`     | `100000` → "$100K - $3M"      |
| Keyword/location | encoded in SRCH path     | `SRCH_IL.0,13_IN1_KO14,26`    |

A fully pre-filtered feed = one Firecrawl GET. No JS interaction needed.

## Pagination

- `_IP<N>.htm` suffix. Page 2 = `..._KO14,26_IP2.htm`. Verified distinct
  results (`pos=201+` vs page-1 `pos=101+`), ~30 cards/page. Total in H1 →
  page count = ceil(total/perPage).

## Verified against (evidence)

| URL | Tier | Result |
|---|---|---|
| `/Job/...SRCH_IL.0,13_IN1_KO14,26.htm` | Firecrawl | statusCode 200, real cards |
| `?remoteWorkType=1&fromAge=7` | Firecrawl | 60 jobs, "Last week" |
| `?easyApply=1&minSalary=100000` | Firecrawl | 4,051 jobs |
| `..._KO14,26_IP2.htm` | Firecrawl | distinct page, pos=201+ |
| `/job-listing/...?jl=1010202371231` | Firecrawl | 403 |
| same detail | CamoFox | Cloudflare "Humans only" |
| `robots.txt` | curl | `/ajax/`, `/jobview/`, `/partner/`, `/profile/` denied; `/Job/` allowed |

VERDICT: PARTIAL
CORRECTION: Fetch #8 (rawHtml) was fabricated (not in the MCP schema); the
"Data surface / no __NEXT_DATA__" conclusion built on it is unverified and
likely wrong. All other actionable extractor claims (Firecrawl 200 on SRCH
feed, card schema, URL filters, `_IP<N>.htm` pagination, per-job 403, robots
rules) were independently reproduced. Verify raw-HTML contents via CamoFox
`navigate` + DOM evaluate before trusting the data-surface section.