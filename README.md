# job-hell

Job listing extractor research for a job pre-screen app. Stack: self-hosted Firecrawl (linux-mint:3002) + CamoFox anti-detection browser (remote backend).

## docs/
- `initial-research.md` — consensus: reachable/blocked/filterable per site + escalation ladder.
- `wellfound.md` `linkedin.md` `greenhouse.md` `lever.md` `dice.md` — FireCrawl-tier extractors.
- `glassdoor.md` — FireCrawl (waitFor+retry) + CamoFox; detail blocked.
- `indeed.md` — requires remote CamoFox backend.
- `ziprecruiter.md` — requires CamoFox.
- `builtin.md` `levelsfyi.md` `otta.md` `remoteok.md` `weworkremotely.md` `workatastartup.md` — stub placeholders (unverified).

## Key facts
- 7 of 8 tested boards scrapeable. Best/least effort: Greenhouse + Lever JSON APIs, Wellfound `__NEXT_DATA__`, Dice.
- Hard: Indeed (remote CamoFox), ZipRecruiter (CamoFox), Glassdoor detail (blocked both tiers).
- Rule: Firecrawl first → waitFor+retry → CamoFox remote. HTTP 200 ≠ success.