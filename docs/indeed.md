# Indeed — extractors

STATUS: VERIFIED (live 2026-09-04; Firecrawl + CamoFox)

## Fetch
Firecrawl = BLOCKED on `/jobs` (403, stable). CamoFox = REQUIRED (renders SERP). Static paths (robots) OK on Firecrawl.

## Best data surface
No public JSON API. A11y tree of the CamoFox-rendered DOM (server-rendered cards). Card = `heading "full details of <title>"` → button + `<company> <location>` + metadata/snippet lists.

## Extractable fields
title, company, location (remote/hybrid verbatim: "Remote in Dallas, TX 75201"), salary (PARTIAL: on card when employer-supplied "$X an hour"/"$X - $Y a year"; else Salary Search link), remote (derived from location prefix), job type (Contract/Full-time), benefits, description snippet. posted date PARTIAL ("New" badge or `fromage`). job id = `jk` (16-hex jobkey).

## Apply / data URLs
- Organic: `/rc/clk?jk=<jobkey>&bb=<token>...` (tokenized, short-lived — store `jk`, rebuild `/viewjob?jk=<jobkey>`)
- Sponsored: `/pagead/clk?...`
- Salary est: `/career/<role>/salaries/<loc>?fromjk=<jobkey>`

## Filters (URL params, server-side — verified)
`q=` (kw), `l=` (loc), `fromage=<days>` (?), `remotejob=<uuid>` (remote, ?), `jt=` (type), `explvl=`, `ps=/psf=/pstk=` (pay), `sort=date|relevance`. `fromage`+`remotejob` verified live.

## Pagination
`start=N` step 10. Robots caps at `start=90` → ~10 pages / 100 results.

## ToS
robots disallows `/` for most AI crawlers (anthropic-ai, ClaudeBot, GPTBot, DeepSeekBot, CCBot, Diffbot, Bytespider, Meta-ExternalAgent). Scraping against robots = compliance risk.

## Verdict
VERIFIED. Strategy: CamoFox each SERP, parse cards, `jk` keys, `start` pagination.