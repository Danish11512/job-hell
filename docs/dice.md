# Dice — extractors

STATUS: VERIFIED (live 2026-09-04; Firecrawl)

## Fetch
`https://www.dice.com/jobs?q=<kw>` → Firecrawl 200, no bot wall, no auth. CamoFox not needed.

## Best data surface
Server-rendered markdown (Firecrawl). Card structure:
```
[<Title>](https://www.dice.com/job-detail/<uuid>)
[<Company>](https://www.dice.com/company-profile/<uuid>?companyname=<Company>)
<City>, <State> • Today/New   Easy Apply   Full-time   $<lo> - $<hi> per annum
```

## Extractable fields
title, company, location ("Carrollton, Texas"), posted (Today/New), employment type (Full-time), salary ($<lo> - $<hi> per annum, e.g. $120000 - $120000), apply link (`/job-detail/<uuid>`), company profile link.

## Filters
Search `q=` param; UI has location/job-type filters. No deep URL-filter research done this pass.

## Verdict
VERIFIED via Firecrawl. Clean, no anti-bot. Strategy: one Firecrawl scrape per `q=`, parse markdown cards.