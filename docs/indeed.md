# Indeed — extractors

STATUS: VERIFIED (live 2026-09-05; remote CamoFox). FireCrawl = BLOCKED. CamoFox local IP = BLOCKED. CamoFox REMOTE backend = WORKS.

## Fetch — which backend matters
- FireCrawl `/jobs?q=<kw>&l=` → `document_antibot` 500, stable. Cannot clear.
- CamoFox LOCAL (127.0.0.1:9377, this Mac's IP) → Cloudflare "Additional Verification Required" interstitial (Ray ID). Own IP is flagged.
- **CamoFox REMOTE (linux-mint exit IP) = REQUIRED and WORKS.** Full SERP renders. 41 job cards in one snapshot.

## Data surface
A11y tree from CamoFox-rendered DOM. Card:
```
heading "full details of <Title>" -> button: <Title>
text: <Company> <City, ST>
list: description snippet / salary / benefits / job type
```
Search box holds the query + full filter bar (Date/Remote/Company sector/Job type/Experience/Pay).

## Extractable fields
title (41 in sample: React Native Developer, iOS Developer, Mobile Solution Architect, ...), company (e.g. JPLoft), salary ($60/hr, $200K–$400K/yr, $109K–$182K/yr), location, apply via `/rc/clk?jk=<jobkey>` (organic) / `/pagead/clk` (sponsored).

## Filters (URL params, server-side — verified)
`q=`, `l=`, `fromage=<days>`, `remotejob=<uuid>`, `jt=`, `explvl=`, `sort=date|relevance`. 

## Pagination
`start=N` step 10; robots caps at `start=90` (~10 pages / 100).

## ToS
robots disallows `/` for most AI crawlers. Scraping against robots = compliance risk.

## Verdict
VERIFIED via **remote** CamoFox backend. Local backend blocked by Cloudflare. Strategy: drive remote CamoFox, parse a11y cards, `jk` keys, `start` pagination.